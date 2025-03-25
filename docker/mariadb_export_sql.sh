#!/bin/bash

# ============ Options ============
VERBOSE=false
DRY_RUN=false
COMPRESS=false

for arg in "$@"; do
  case $arg in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --compress)
      COMPRESS=true
      shift
      ;;
  esac
done

log() {
  if [ "$VERBOSE" = true ]; then
    echo "$1"
  fi
}

# ============ Chargement des variables depuis .env ============
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ Fichier .env manquant. Abandon."
  exit 1
fi

# ============ Vérification des variables essentielles ============
[ -z "$DB_HOST" ] && read -p "🔌 Nom du conteneur (DB_HOST) : " DB_HOST
[ -z "$DB_DATABASE" ] && read -p "🗃️ Nom de la base (DB_DATABASE) : " DB_DATABASE
[ -z "$DB_USERNAME" ] && read -p "👤 Utilisateur (DB_USERNAME) : " DB_USERNAME
[ -z "$DB_PASSWORD" ] && read -s -p "🔑 Mot de passe (DB_PASSWORD) : " DB_PASSWORD && echo

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_NAME="${DB_DATABASE}_${TIMESTAMP}.sql"

log "Conteneur : $DB_HOST"
log "Base      : $DB_DATABASE"
log "Fichier   : $EXPORT_NAME"

# ============ Mode Dry-Run ============
if [ "$DRY_RUN" = true ]; then
  echo "🧪 [Dry Run] Voici la commande qui serait lancée :"
  echo "docker exec $DB_HOST mysqldump -u$DB_USERNAME -p***** $DB_DATABASE > $EXPORT_NAME"
  exit 0
fi

# ============ Export ============
docker exec "$DB_HOST" \
  bash -c "mysqldump -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE" > "$EXPORT_NAME"

if [ $? -ne 0 ]; then
  echo "❌ Échec de l'export."
  exit 2
fi

# ============ Compression optionnelle ============
if [ "$COMPRESS" = true ]; then
  gzip "$EXPORT_NAME"
  EXPORT_NAME="$EXPORT_NAME.gz"
  log "✅ Fichier compressé : $EXPORT_NAME"
else
  log "✅ Export SQL terminé : $EXPORT_NAME"
fi
