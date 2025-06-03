#!/bin/bash

# === CONFIGURATION DU LOG ===
LOG_FILE="./migration_db.log"
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

# === VALIDATION DES ARGUMENTS ===
if [ "$#" -lt 3 ]; then
    log "❌ Usage: $0 <db_user> <db_password> <remote_host> [--no-blocking] [--dry-run] [--path=/chemin] [--restore] [--db=nom]"
    exit 1
fi

DB_USER="$1"
DB_PASSWORD="$2"
REMOTE_HOST="$3"
shift 3

# === FLAGS ===
BLOCKING=true
DRY_RUN=false
REMOTE_PATH="~"
RESTORE=false
SPECIFIC_DB=""
for arg in "$@"; do
    case $arg in
        --no-blocking) BLOCKING=false ;;
        --dry-run) DRY_RUN=true ;;
        --restore) RESTORE=true ;;
        --path=*) REMOTE_PATH="${arg#*=}" ;;
        --db=*) SPECIFIC_DB="${arg#*=}" ;;
    esac
done

# === SI NON BLOQUANT, RELANCER EN ARRIÈRE-PLAN ===
if ! $BLOCKING; then
    log "⏱ Lancement de la migration en arrière-plan..."
    nohup bash "$0" "$DB_USER" "$DB_PASSWORD" "$REMOTE_HOST" --dry-run=$DRY_RUN --path=$REMOTE_PATH --restore=$RESTORE --db=$SPECIFIC_DB >> "$LOG_FILE" 2>&1 &
    log "🧬 Migration démarrée en arrière-plan (PID $!)."
    exit 0
fi

BACKUP_DIR="db_backup_$(date +%Y%m%d_%H%M%S)"
ARCHIVE_NAME="${BACKUP_DIR}.tar.gz"
HASH_NAME="${ARCHIVE_NAME}.sha256"

# === EXPORT DES BASES DE DONNÉES ===
if [ -n "$SPECIFIC_DB" ]; then
    DATABASES="$SPECIFIC_DB"
    log "🎯 Export ciblé uniquement pour la base: $SPECIFIC_DB"
else
    log "🧩 Récupération des bases de données disponibles..."
    DATABASES=$(mysql -u"$DB_USER" -p"$DB_PASSWORD" -e 'SHOW DATABASES;' | grep -Ev "^(Database|information_schema|performance_schema|mysql|sys)$")
fi

if [ -z "$DATABASES" ]; then
    log "❌ Aucune base de données à exporter."
    exit 1
fi

if $DRY_RUN; then
    log "🧪 [dry-run] Simulation de l'export des bases de données :"
    for DB in $DATABASES; do
        log "🔄 [dry-run] Simulation export: $DB => $BACKUP_DIR/${DB}.sql"
    done
    log "📦 [dry-run] Compression simulée: $ARCHIVE_NAME"
    log "🔐 [dry-run] Génération hash SHA256 simulée: $HASH_NAME"
    log "🚀 [dry-run] Transfert simulé vers $REMOTE_HOST:$REMOTE_PATH"
    log "📂 [dry-run] Décompression simulée sur le serveur distant dans $REMOTE_PATH"
    if $RESTORE; then
        log "♻️ [dry-run] Restauration simulée sur le serveur distant."
    fi
    log "🧹 [dry-run] Nettoyage simulé des fichiers locaux"
    log "✅ [dry-run] Migration simulée avec succès."
    exit 0
fi

mkdir -p "$BACKUP_DIR"
log "📦 Export des bases dans le dossier $BACKUP_DIR..."
for DB in $DATABASES; do
    log "🔄 Export de la base: $DB"
    mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB" > "$BACKUP_DIR/${DB}.sql"
    if [ $? -ne 0 ]; then
        log "❌ Échec de l'export de la base: $DB"
        exit 1
    fi
    log "✅ Base $DB exportée."
done

# === COMPRESSION DE L'ARCHIVE ===
log "📦 Compression de l'archive: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_NAME" "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    log "❌ Échec de la compression de l'archive."
    exit 1
fi

# === GÉNÉRATION DU HASH ===
log "🔐 Génération du hash SHA256..."
sha256sum "$ARCHIVE_NAME" | awk '{print $1}' > "$HASH_NAME"

# === TRANSFERT VERS LE SERVEUR DISTANT ===
log "🚀 Transfert de l'archive et du hash vers $REMOTE_HOST:$REMOTE_PATH..."
scp "$ARCHIVE_NAME" "$HASH_NAME" "$REMOTE_HOST:$REMOTE_PATH/"
if [ $? -ne 0 ]; then
    log "❌ Échec du transfert."
    exit 1
fi

# === VÉRIFICATION DU HASH DISTANT ===
log "🔍 Vérification de l'intégrité côté serveur..."
ssh "$REMOTE_HOST" "cd $REMOTE_PATH && sha256sum -c <<< \"\$(cat $HASH_NAME)  $ARCHIVE_NAME\""
if [ $? -ne 0 ]; then
    log "❌ Vérification SHA256 échouée : fichier corrompu ou altéré."
    exit 1
else
    log "✅ Vérification SHA256 réussie : intégrité confirmée."
fi

# === DÉCOMPRESSION CÔTÉ DISTANT ===
log "📂 Décompression de l'archive sur le serveur distant dans $REMOTE_PATH..."
ssh "$REMOTE_HOST" "cd $REMOTE_PATH && tar -xzf $ARCHIVE_NAME && rm $ARCHIVE_NAME $HASH_NAME"
if [ $? -ne 0 ]; then
    log "❌ Échec de la décompression distante."
    exit 1
fi

# === RESTAURATION CÔTÉ DISTANT ===
if $RESTORE; then
    log "♻️ Restauration des bases sur le serveur distant..."
    ssh "$REMOTE_HOST" "cd $REMOTE_PATH/$BACKUP_DIR && for sql in *.sql; do DB=\"$(basename \"$sql\" .sql)\"; mysql -u\"$DB_USER\" -p\"$DB_PASSWORD\" -e \"CREATE DATABASE IF NOT EXISTS \\\\`$DB\\\`; USE \\\\`$DB\\\`; source \"\$sql\";\"; done"
    if [ $? -ne 0 ]; then
        log "❌ Échec de la restauration des bases de données."
        exit 1
    fi
    log "✅ Bases restaurées avec succès sur le serveur distant."
fi

# === NETTOYAGE LOCAL ===
log "🧹 Nettoyage local..."
rm -rf "$ARCHIVE_NAME" "$HASH_NAME" "$BACKUP_DIR"

# === FIN ===
log "✅ Migration des bases de données terminée avec succès."
exit 0
