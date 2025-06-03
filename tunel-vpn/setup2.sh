#!/bin/bash

# =====================================
# Script de gestion de tunnels VPN WireGuard via SSH
# Permet de créer, configurer, tester, lister et supprimer des tunnels VPN site-à-site
# =====================================

set -e

# --- Affichage de l'aide ---
show_help() {
  echo "\nUSAGE : ./script.sh"
  echo "\nOPTIONS :"
  echo "  --help             Affiche cette aide."
  echo "\nFONCTIONNALITÉS :"
  echo "  Ce script vous permet de :"
  echo "    1. Créer un tunnel VPN entre deux serveurs via SSH."
  echo "    2. Lister les tunnels existants (et les configurations actives)."
  echo "    3. Supprimer un tunnel existant et ses configurations."
  echo "    4. Reconfigurer complètement un tunnel existant."
  echo "    5. Tester la connectivité VPN entre les deux machines."
  echo "\nExécution du script sans arguments ouvrira un menu interactif."
  exit 0
}

# Vérification des options
if [[ "$1" == "--help" ]]; then
  show_help
fi

if [[ "$1" == "--helper" ]]; then
  echo "[INFO] Ce script permet de gérer des tunnels VPN WireGuard entre deux serveurs via SSH."
  echo "Il stocke les configurations dans des fichiers .env personnalisés et déploie automatiquement les configurations."
  echo "Chaque action est guidée via un menu interactif (création, test, suppression, reconfiguration)."
  echo "Utilisez './script.sh --help' pour les options détaillées ou lancez le script sans arguments."
  exit 0
fi
if [[ "$1" == "--help" ]]; then
  show_help
fi

# --- Lancement du menu interactif principal ---

# --- Menu principal ---
echo "=== GESTION DE TUNNELS VPN WIREGUARD ==="
echo "1. Créer un nouveau tunnel"
echo "2. Lister les tunnels existants"
echo "3. Supprimer un tunnel existant"
echo "4. Quitter"
echo "5. Reconfigurer un tunnel existant"
read -p "Choix [1-5] : " CHOICE

read -p "Dossier de stockage des fichiers .env (laisser vide pour /etc/wireguard) : " ENV_DIR
ENV_DIR=${ENV_DIR:-/etc/wireguard}

case "$CHOICE" in
  1)
    read -p "Nom unique pour identifier ce tunnel (ex: bureau-maison) : " TUNNEL_ID
    ENV_FILE="$ENV_DIR/.env.wg-$TUNNEL_ID"
    if [ -f "$ENV_FILE" ]; then
      echo "[INFO] Chargement des variables depuis $ENV_FILE"
      source "$ENV_FILE"
    else
      echo "[INFO] Création d'un nouveau tunnel ($TUNNEL_ID)"
      read -p "Adresse SSH du serveur local : " LOCAL_SSH
      read -s -p "Mot de passe sudo pour le serveur local : " LOCAL_PASS
      echo
      read -p "Adresse SSH du serveur distant : " REMOTE_SSH
      read -s -p "Mot de passe sudo pour le serveur distant : " REMOTE_PASS
      echo
      read -p "Adresse VPN pour le serveur local : " LOCAL_VPN_IP
      read -p "Adresse VPN pour le serveur distant : " REMOTE_VPN_IP
      read -p "Port WireGuard : " PORT
      read -p "IP publique du serveur distant : " REMOTE_IP
      mkdir -p "$ENV_DIR"
      echo "LOCAL_SSH=\"$LOCAL_SSH\"" > "$ENV_FILE"
      echo "LOCAL_PASS=\"$LOCAL_PASS\"" >> "$ENV_FILE"
      echo "REMOTE_SSH=\"$REMOTE_SSH\"" >> "$ENV_FILE"
      echo "REMOTE_PASS=\"$REMOTE_PASS\"" >> "$ENV_FILE"
      echo "LOCAL_VPN_IP=\"$LOCAL_VPN_IP\"" >> "$ENV_FILE"
      echo "REMOTE_VPN_IP=\"$REMOTE_VPN_IP\"" >> "$ENV_FILE"
      echo "PORT=\"$PORT\"" >> "$ENV_FILE"
      echo "REMOTE_IP=\"$REMOTE_IP\"" >> "$ENV_FILE"
    fi
    install_wireguard "$LOCAL_SSH" "$LOCAL_PASS"
    install_wireguard "$REMOTE_SSH" "$REMOTE_PASS"
    generate_keys "$LOCAL_SSH"
    generate_keys "$REMOTE_SSH"
    LOCAL_PUB=$(get_public_key "$LOCAL_SSH")
    REMOTE_PUB=$(get_public_key "$REMOTE_SSH")
    LOCAL_PRIV=$(get_private_key "$LOCAL_SSH")
    REMOTE_PRIV=$(get_private_key "$REMOTE_SSH")
    create_config "$LOCAL_SSH" "$LOCAL_PASS" "$LOCAL_PRIV" "$LOCAL_VPN_IP" 0 "$REMOTE_PUB" "$REMOTE_IP" "$PORT" "$REMOTE_VPN_IP"
    create_config "$REMOTE_SSH" "$REMOTE_PASS" "$REMOTE_PRIV" "$REMOTE_VPN_IP" "$PORT" "$LOCAL_PUB" "$LOCAL_VPN_IP" 0 "$LOCAL_VPN_IP"
    enable_service "$LOCAL_SSH" "$LOCAL_PASS"
    enable_service "$REMOTE_SSH" "$REMOTE_PASS"
    test_connectivity
    echo "[OK] Le tunnel VPN WireGuard est configuré et actif entre les deux serveurs."
    echo "Clé publique du serveur local : $LOCAL_PUB"
    echo "Clé publique du serveur distant : $REMOTE_PUB"
    ;;
  2)
    read -p "Adresse SSH du serveur local pour vérification : " LOCAL_SSH
    read -p "Adresse SSH du serveur distant pour vérification : " REMOTE_SSH
    list_tunnels
    ;;
  3)
    read -p "Nom du tunnel à supprimer : " TUNNEL_ID
    ENV_FILE="$ENV_DIR/.env.wg-$TUNNEL_ID"
    if [ ! -f "$ENV_FILE" ]; then
      echo "[ERREUR] Fichier $ENV_FILE introuvable."
      exit 1
    fi
    source "$ENV_FILE"
    delete_tunnel
    ;;
  4)
    echo "Sortie."
    exit 0
    ;;
  5)
    read -p "Nom du tunnel à reconfigurer : " TUNNEL_ID
    ENV_FILE="$ENV_DIR/.env.wg-$TUNNEL_ID"
    if [ ! -f "$ENV_FILE" ]; then
      echo "[ERREUR] Fichier $ENV_FILE introuvable."
      exit 1
    fi
    source "$ENV_FILE"
    echo "[INFO] Réinitialisation du tunnel WireGuard $TUNNEL_ID..."
    install_wireguard "$LOCAL_SSH" "$LOCAL_PASS"
    install_wireguard "$REMOTE_SSH" "$REMOTE_PASS"
    generate_keys "$LOCAL_SSH"
    generate_keys "$REMOTE_SSH"
    LOCAL_PUB=$(get_public_key "$LOCAL_SSH")
    REMOTE_PUB=$(get_public_key "$REMOTE_SSH")
    LOCAL_PRIV=$(get_private_key "$LOCAL_SSH")
    REMOTE_PRIV=$(get_private_key "$REMOTE_SSH")
    create_config "$LOCAL_SSH" "$LOCAL_PASS" "$LOCAL_PRIV" "$LOCAL_VPN_IP" 0 "$REMOTE_PUB" "$REMOTE_IP" "$PORT" "$REMOTE_VPN_IP"
    create_config "$REMOTE_SSH" "$REMOTE_PASS" "$REMOTE_PRIV" "$REMOTE_VPN_IP" "$PORT" "$LOCAL_PUB" "$LOCAL_VPN_IP" 0 "$LOCAL_VPN_IP"
    enable_service "$LOCAL_SSH" "$LOCAL_PASS"
    enable_service "$REMOTE_SSH" "$REMOTE_PASS"
    test_connectivity
    echo "[OK] Le tunnel $TUNNEL_ID a été reconfiguré."
    ;;
  *)
    echo "Choix invalide."
    exit 1
    ;;
esac
