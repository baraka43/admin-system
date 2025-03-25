#!/bin/bash

# ============ Options ============
VERBOSE=false
DRY_RUN=false

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
fi

# ============ Lecture interactive des variables manquantes ============

[ -z "$DB_HOST" ] && read -p "🔌 Nom du conteneur base de données (DB_HOST) : " DB_HOST
[ -z "$DB_DATABASE" ] && read -p "🗃️ Nom de la base de données (DB_DATABASE) : " DB_DATABASE
[ -z "$DB_USERNAME" ] && read -p "👤 Nom d'utilisateur (DB_USERNAME) [defaut: root] : " DB_USERNAME
DB_USERNAME=${DB_USERNAME:-root}
[ -z "$DB_PASSWORD" ] && read -s -p "🔑 Mot de passe utilisateur (DB_PASSWORD) : " DB_PASSWORD && echo
[ -z "$DB_INIT_SQL_FILE" ] && read -p "📄 Chemin du fichier SQL (DB_INIT_SQL_FILE) : " DB_INIT_SQL_FILE

# ============ Vérifications ============

if [ ! -f "$DB_INIT_SQL_FILE" ]; then
  echo "❌ Fichier SQL introuvable : $DB_INIT_SQL_FILE"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_HOST}$"; then
  echo "❌ Le conteneur '$DB_HOST' n'est pas en cours d'exécution."
  exit 2
fi

log "📋 Configuration :"
log "Conteneur   : $DB_HOST"
log "Fichier SQL : $DB_INIT_SQL_FILE"
log "Utilisateur : $DB_USERNAME"
log "Base cible  : $DB_DATABASE"

# ============ Mode Dry-Run ============

if [ "$DRY_RUN" = true ]; then
  echo "🧪 [Dry Run] Import NON exécuté. Voici la commande qui serait lancée :"
  echo "docker exec -i $DB_HOST mysql -u$DB_USERNAME -p***** $DB_DATABASE < $DB_INIT_SQL_FILE"
  exit 0
fi

# ============ Copie du fichier SQL ============
TMP_SQL_PATH="/tmp/import-env.sql"
docker cp "$DB_INIT_SQL_FILE" "$DB_HOST:$TMP_SQL_PATH"

# ============ Création de la base ============
docker exec "$DB_HOST" \
  bash -c "mysql -u$DB_USERNAME -p$DB_PASSWORD -e 'CREATE DATABASE IF NOT EXISTS \`$DB_DATABASE\`;'" || {
    echo "❌ Erreur création base."
    exit 3
  }

# ============ Import SQL ============
docker exec -i "$DB_HOST" \
  bash -c "mysql -u$DB_USERNAME -p$DB_PASSWORD $DB_DATABASE -e 'source $TMP_SQL_PATH'" || {
    echo "❌ Erreur d'importation."
    exit 4
  }

# ============ Nettoyage ============
docker exec "$DB_HOST" rm -f "$TMP_SQL_PATH"
echo "✅ Importation réussie dans '$DB_DATABASE'."
