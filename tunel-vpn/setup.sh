#!/bin/bash

# Script interactif de configuration d'un tunnel VPN WireGuard entre deux serveurs Ubuntu via SSH.
# Ce script installe WireGuard, génère les clés, configure les interfaces VPN et active le service automatiquement.

set -e

# --- Lister tous les fichiers .env existants ---
if [[ "$1" == "--list" ]]; then
  echo "[INFO] Tunnels WireGuard disponibles :"
  ls .env.wg-* 2>/dev/null || echo "Aucun tunnel trouvé."
  exit 0
fi

# --- Charger les variables d'environnement si un fichier .env existe ---
read -p "Nom unique pour identifier ce tunnel (ex: bureau-maison) : " TUNNEL_ID
ENV_FILE=".env.wg-$TUNNEL_ID"

if [ -f "$ENV_FILE" ]; then
  echo "[INFO] Chargement des variables depuis $ENV_FILE"
  source "$ENV_FILE"
else
  echo "[INFO] Fichier $ENV_FILE non trouvé. Création en cours."

  read -p "Adresse SSH du serveur local (ex: user@192.168.1.10) : " LOCAL_SSH
  read -s -p "Mot de passe sudo pour le serveur local : " LOCAL_PASS
  echo
  read -p "Adresse SSH du serveur distant (ex: user@IP_PUBLIQUE) : " REMOTE_SSH
  read -s -p "Mot de passe sudo pour le serveur distant : " REMOTE_PASS
  echo
  read -p "Adresse VPN pour le serveur local (ex: 10.10.0.2) : " LOCAL_VPN_IP
  read -p "Adresse VPN pour le serveur distant (ex: 10.10.0.1) : " REMOTE_VPN_IP
  read -p "Port d'écoute WireGuard (ex: 51820) : " PORT
  read -p "IP publique du serveur distant : " REMOTE_IP

  echo "LOCAL_SSH=\"$LOCAL_SSH\"" > "$ENV_FILE"
  echo "LOCAL_PASS=\"$LOCAL_PASS\"" >> "$ENV_FILE"
  echo "REMOTE_SSH=\"$REMOTE_SSH\"" >> "$ENV_FILE"
  echo "REMOTE_PASS=\"$REMOTE_PASS\"" >> "$ENV_FILE"
  echo "LOCAL_VPN_IP=\"$LOCAL_VPN_IP\"" >> "$ENV_FILE"
  echo "REMOTE_VPN_IP=\"$REMOTE_VPN_IP\"" >> "$ENV_FILE"
  echo "PORT=\"$PORT\"" >> "$ENV_FILE"
  echo "REMOTE_IP=\"$REMOTE_IP\"" >> "$ENV_FILE"
fi

# --- Fonction : Exécuter une commande sudo sur une machine distante avec mot de passe passé une fois ---
run_sudo_cmd() {
  SERVER="$1"
  PASSWORD="$2"
  shift 2
  ssh "$SERVER" "echo '$PASSWORD' | sudo -S $@"
}

# --- Fonction : Installer WireGuard sur un serveur donné ---
install_wireguard() {
  run_sudo_cmd "$1" "$2" "apt update && apt install -y wireguard"
}

# --- Fonction : Générer les clés WireGuard sur le serveur ciblé ---
generate_keys() {
  ssh "$1" "mkdir -p ~/wireguard-keys && cd ~/wireguard-keys && wg genkey | tee privatekey | wg pubkey > publickey"
}

# --- Fonction : Récupérer la clé publique du serveur ciblé ---
get_public_key() {
  ssh "$1" "cat ~/wireguard-keys/publickey"
}

# --- Fonction : Récupérer la clé privée du serveur ciblé ---
get_private_key() {
  ssh "$1" "cat ~/wireguard-keys/privatekey"
}

# --- Fonction : Créer la configuration VPN sur le serveur ciblé ---
create_config() {
  ssh "$1" "echo '$2' | sudo -S bash -c 'cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $3
Address = $4/24
ListenPort = $5

[Peer]
PublicKey = $6
Endpoint = $7:$8
AllowedIPs = $9/32
PersistentKeepalive = 25
EOF'"
  run_sudo_cmd "$1" "$2" "chmod 600 /etc/wireguard/wg0.conf"
}

# --- Fonction : Activer le service WireGuard ---
enable_service() {
  run_sudo_cmd "$1" "$2" "systemctl enable wg-quick@wg0 && systemctl start wg-quick@wg0"
}

# --- Installation de WireGuard sur les deux serveurs ---
install_wireguard "$LOCAL_SSH" "$LOCAL_PASS"
install_wireguard "$REMOTE_SSH" "$REMOTE_PASS"

# --- Génération des clés sur les deux serveurs ---
generate_keys "$LOCAL_SSH"
generate_keys "$REMOTE_SSH"

# --- Récupération des clés publiques et privées ---
LOCAL_PUB=$(get_public_key "$LOCAL_SSH")
REMOTE_PUB=$(get_public_key "$REMOTE_SSH")
LOCAL_PRIV=$(get_private_key "$LOCAL_SSH")
REMOTE_PRIV=$(get_private_key "$REMOTE_SSH")

# --- Création des configurations WireGuard sur chaque serveur ---
create_config "$LOCAL_SSH" "$LOCAL_PASS" "$LOCAL_PRIV" "$LOCAL_VPN_IP" 0 "$REMOTE_PUB" "$REMOTE_IP" "$PORT" "$REMOTE_VPN_IP"
create_config "$REMOTE_SSH" "$REMOTE_PASS" "$REMOTE_PRIV" "$REMOTE_VPN_IP" "$PORT" "$LOCAL_PUB" "$LOCAL_VPN_IP" 0 "$LOCAL_VPN_IP"

# --- Activation du service WireGuard ---
enable_service "$LOCAL_SSH" "$LOCAL_PASS"
enable_service "$REMOTE_SSH" "$REMOTE_PASS"

# --- Affichage final ---
echo "[OK] Le tunnel VPN WireGuard est configuré et actif entre les deux serveurs."
echo "Clé publique du serveur local : $LOCAL_PUB"
echo "Clé publique du serveur distant : $REMOTE_PUB"
