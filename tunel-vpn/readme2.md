# 📘 Guide d'utilisation — WireGuard VPN Tunnel Manager

Ce script Bash permet de gérer facilement des tunnels VPN site-à-site en utilisant WireGuard via SSH. Grâce à son menu interactif, vous pouvez créer, configurer, tester, lister et supprimer des tunnels entre deux serveurs Ubuntu de manière sécurisée et automatisée.

---

## 🚀 Fonctionnalités principales

- Installation automatique de WireGuard sur les deux machines via SSH
- Génération des paires de clés WireGuard (privée/publique)
- Création et déploiement automatique des fichiers de configuration `/etc/wireguard/wg0.conf`
- Activation du service `wg-quick@wg0` au démarrage du système
- Test de connectivité entre les deux serveurs via VPN (ping bidirectionnel)
- Menu interactif simple et intuitif
- Options en ligne de commande : `--help`, `--helper`

---

## ✅ Prérequis

- Deux serveurs Ubuntu avec accès SSH
- Accès sudo sur chaque machine (le mot de passe ne sera demandé qu’une fois)
- Port UDP ouvert (par défaut : 51820) pour la communication WireGuard

---

## 💻 Lancer le script

### Menu interactif
```bash
./script.sh
```
Un menu vous sera proposé avec les choix suivants :

1. Créer un nouveau tunnel VPN
2. Lister les tunnels existants
3. Supprimer un tunnel existant
4. Quitter
5. Reconfigurer un tunnel existant

### Options en ligne
```bash
./script.sh --help    # Affiche l'aide détaillée
./script.sh --helper  # Résumé du fonctionnement du script
```

---

## 🔐 Gestion des tunnels VPN

Chaque tunnel est associé à un fichier `.env.wg-<nom>` contenant les informations de configuration (adresses, clés, ports, etc.). Ces fichiers sont stockés dans le répertoire `/etc/wireguard` par défaut, mais vous pouvez en spécifier un autre.

Ces fichiers facilitent :
- La reconfiguration rapide des tunnels
- La suppression propre d’un tunnel
- La persistance des données sans devoir tout ressaisir

---

## 🧪 Exemple d’utilisation

1. Lancer le script et sélectionner "Créer un tunnel"
2. Fournir les informations SSH, IP VPN, port et adresse IP publique
3. Le script configure automatiquement les deux serveurs
4. Une fois le tunnel actif, vous pouvez vous connecter :
```bash
ssh user@10.10.0.1
```

---

## 📜 Licence

Ce script est fourni librement, sans garantie. Vous êtes autorisé à le modifier et à l’utiliser dans vos projets personnels ou professionnels. Utilisation à vos risques et périls.

---

Développé pour simplifier la gestion des tunnels WireGuard à distance.

