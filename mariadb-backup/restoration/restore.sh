#!/bin/bash

ENV_FILE=".env"

# === CHARGEMENT OU CRÉATION DU FICHIER .env ===
if [ -f "$ENV_FILE" ]; then
  echo "✅ Chargement des variables depuis $ENV_FILE"
  source "$ENV_FILE"
else
  echo "⚠️ Aucune configuration trouvée. Création interactive..."
  read -rp "Nom d'utilisateur MariaDB : " DB_USER
  read -rsp "Mot de passe MariaDB : " DB_PASS
  echo ""
  read -rp "Chemin du dossier de sauvegarde (ex: /mnt/backup) : " BACKUP_DIR

  cat > "$ENV_FILE" <<EOF
DB_USER=$DB_USER
DB_PASS=$DB_PASS
BACKUP_DIR=$BACKUP_DIR
EOF

  echo "✅ Fichier .env créé."
fi

# === VARIABLES INTERNES ===
FULL_DIR="$BACKUP_DIR/full"
LOG_FILE="$BACKUP_DIR/restore.log"

# === CHOIX DU MODE DE RESTAURATION ===
echo ""
echo "=== 🧩 Restauration MariaDB ==="
echo "1. Restaurer uniquement la sauvegarde complète"
echo "2. Restaurer la sauvegarde complète + toutes les incrémentales"
read -rp "Choisis une option (1 ou 2) : " RESTORE_MODE

# === ARRÊT DU SERVICE ===
echo "📛 Arrêt de MariaDB..."
sudo systemctl stop mariadb

# === PRÉPARATION ===
if [ "$RESTORE_MODE" == "1" ]; then
  echo "🧪 Préparation de la sauvegarde complète uniquement..."
  mariabackup --prepare --target-dir="$FULL_DIR"
elif [ "$RESTORE_MODE" == "2" ]; then
  echo "🧪 Préparation complète + incrémentales..."
  mariabackup --prepare --target-dir="$FULL_DIR"

  INCR_DIRS=($(ls -1d "$BACKUP_DIR"/incr-* 2>/dev/null | sort))
  for DIR in "${INCR_DIRS[@]}"; do
    echo "➕ Application de $DIR..."
    mariabackup --prepare --target-dir="$FULL_DIR" --incremental-dir="$DIR"
  done
else
  echo "❌ Option invalide. Abandon."
  exit 1
fi

# === COPIE DES FICHIERS ===
echo "🛠️ Copie des fichiers dans /var/lib/mysql..."
sudo rsync -av "$FULL_DIR/" /var/lib/mysql/
sudo chown -R mysql:mysql /var/lib/mysql

# === REDÉMARRAGE DU SERVICE ===
echo "🚀 Redémarrage de MariaDB..."
sudo systemctl start mariadb

echo "✅ Restauration terminée. Consulte le journal pour vérifier : $LOG_FILE"
