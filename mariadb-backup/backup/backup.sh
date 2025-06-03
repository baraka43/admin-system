#!/bin/bash

ENV_FILE=".env"

# === CHARGEMENT OU CRÉATION DES VARIABLES ===
if [ -f "$ENV_FILE" ]; then
  echo "✅ Chargement de $ENV_FILE"
  source "$ENV_FILE"
else
  echo "⚠️ Aucune configuration trouvée. Création..."
  read -rp "Utilisateur MariaDB : " DB_USER
  read -rsp "Mot de passe MariaDB : " DB_PASS
  echo ""
  read -rp "Dossier de sauvegarde (ex: /mnt/backup) : " BACKUP_DIR
  cat > "$ENV_FILE" <<EOF
DB_USER=$DB_USER
DB_PASS=$DB_PASS
BACKUP_DIR=$BACKUP_DIR
EOF
  echo "✅ Fichier $ENV_FILE créé."
fi

# === VARIABLES INTERNES ===
FULL_DIR="$BACKUP_DIR/full"
DATE=$(date +%F)
INCR_DIR="$BACKUP_DIR/incr-$DATE"
LOG_FILE="$BACKUP_DIR/backup.log"
TMP_DIR="$BACKUP_DIR/tmp-merge"

mkdir -p "$BACKUP_DIR"

# === SI SAUVEGARDE DÉJÀ FAITE AUJOURD'HUI ===
if [ -d "$INCR_DIR" ]; then
  echo "[$(date)] ✅ Sauvegarde déjà effectuée aujourd'hui. Fin." | tee -a "$LOG_FILE"
  exit 0
fi

# === SAUVEGARDE COMPLÈTE SI AUCUNE N'EXISTE ===
if [ ! -f "$FULL_DIR/xtrabackup_checkpoints" ]; then
  echo "[$(date)] 🔰 Première sauvegarde complète..." | tee -a "$LOG_FILE"
  mkdir -p "$FULL_DIR"
  mariabackup --backup --target-dir="$FULL_DIR" --user="$DB_USER" --password="$DB_PASS"
  echo "[$(date)] ✅ Complète terminée." | tee -a "$LOG_FILE"
  exit 0
fi

# === SAUVEGARDE INCRÉMENTALE ===
echo "[$(date)] 🔁 Sauvegarde incrémentale vers $INCR_DIR..." | tee -a "$LOG_FILE"
mkdir -p "$INCR_DIR"
mariabackup --backup \
  --target-dir="$INCR_DIR" \
  --incremental-basedir="$FULL_DIR" \
  --user="$DB_USER" --password="$DB_PASS"
echo "[$(date)] ✅ Incrémentale terminée." | tee -a "$LOG_FILE"

# === VÉRIFIER SI 7 INCRÉMENTALES EXISTENT ===
INCR_LIST=($(ls -1d "$BACKUP_DIR"/incr-* 2>/dev/null | sort))
if [ ${#INCR_LIST[@]} -lt 7 ]; then
  echo "[$(date)] ℹ️ Moins de 7 incrémentales. Pas de consolidation." | tee -a "$LOG_FILE"
  exit 0
fi

# === FUSION DES INCRÉMENTALES ===
echo "[$(date)] ♻️ Fusion des 7 premières incrémentales dans une nouvelle sauvegarde complète..." | tee -a "$LOG_FILE"
rm -rf "$TMP_DIR"
cp -a "$FULL_DIR" "$TMP_DIR"

for incr in "${INCR_LIST[@]:0:7}"; do
  echo "[$(date)] ➕ Application de $incr..." | tee -a "$LOG_FILE"
  mariabackup --prepare --target-dir="$TMP_DIR" --incremental-dir="$incr"
done

# Sauvegarde temporaire devient la nouvelle complète
mv "$FULL_DIR" "${FULL_DIR}_old_$(date +%s)"
mv "$TMP_DIR" "$FULL_DIR"
echo "[$(date)] ✅ Fusion terminée." | tee -a "$LOG_FILE"

# Nettoyage
for incr in "${INCR_LIST[@]:0:7}"; do
  echo "[$(date)] 🧹 Suppression de $incr..." | tee -a "$LOG_FILE"
  rm -rf "$incr"
done

echo "[$(date)] ✅ Consolidation et nettoyage terminés." | tee -a "$LOG_FILE"
