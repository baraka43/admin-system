# Guide d'utilisation — Script de configuration automatique d'un tunnel VPN WireGuard (Site-à-Site)

Ce document décrit le fonctionnement d’un script Bash destiné à configurer automatiquement un tunnel **VPN site-à-site sécurisé avec WireGuard** entre deux serveurs **Ubuntu**, en utilisant des connexions **SSH**. Le script automatise l’installation, la génération de clés, la configuration du tunnel et l’activation du service au démarrage.

---

## 🔧 Fonctionnalités principales

- Installation automatique de WireGuard (si non présent)
- Génération de paires de clés privées/publics sur chaque serveur
- Création du fichier de configuration `/etc/wireguard/wg0.conf`
- Définition dynamique des IP VPN locales et distantes
- Activation automatique du tunnel VPN au démarrage via `systemd`
- Interface interactive pour guider l'utilisateur étape par étape

---

## 💡 Cas d'utilisation courant

Ce script est particulièrement utile dans les cas suivants :

- **Exposition sécurisée d’un service local** (ex : une bibliothèque numérique, une interface de gestion locale, une API interne)
- **Administration distante d’un serveur** sans redirection de port sur la box ou pare-feu
- **Connexion permanente entre un VPS public et un serveur local** situé derrière un NAT
- **Interconnexion de deux réseaux locaux distants** via un tunnel VPN léger et stable

---

## 🧰 Prérequis

Avant de lancer le script, assurez-vous de disposer des éléments suivants :

- Deux serveurs fonctionnant sous **Ubuntu** (versions récentes recommandées)
- Un **accès SSH fonctionnel** aux deux machines, avec un compte disposant de droits `sudo`
- Un port **UDP ouvert sur le serveur distant** (généralement `51820` pour WireGuard)
- L’autorisation d’installer des paquets (`apt`) et de modifier les fichiers système
- L’accès Internet pour le téléchargement des paquets nécessaires

---

## 🚀 Instructions d'utilisation

### Étape 1 : Exécution du script
Lancez le script depuis **une seule des deux machines** (peu importe laquelle) :

```bash
bash wireguard-setup.sh
```

### Étape 2 : Répondre aux questions interactives
Le script vous demandera successivement :

- L'adresse SSH du serveur local (ex : `user@192.168.1.100`)
- L'adresse SSH du serveur distant (ex : `user@1.2.3.4`)
- L’adresse VPN souhaitée pour le local (ex : `10.10.0.2`)
- L’adresse VPN souhaitée pour le distant (ex : `10.10.0.1`)
- Le port WireGuard à utiliser (généralement `51820`)
- L’adresse IP publique du serveur distant

### Exemple d’entrée :
```
Adresse SSH du serveur local : user@192.168.1.100
Adresse SSH du serveur distant : user@1.2.3.4
Adresse VPN pour le local : 10.10.0.2
Adresse VPN pour le distant : 10.10.0.1
Port WireGuard : 51820
IP publique du distant : 1.2.3.4
```

---

## ✅ Résultat attendu

- Un tunnel VPN sécurisé est établi entre les deux serveurs
- Les commandes suivantes fonctionnent :
  - `ping 10.10.0.1` depuis le serveur local
  - `ping 10.10.0.2` depuis le serveur distant
- Le service `wg-quick@wg0` est activé sur les deux machines et redémarre automatiquement

---

## 🧪 Exemple d'utilisation de la connexion VPN

Une fois le tunnel actif, voici quelques exemples pratiques :

- Connexion SSH au serveur local via son IP VPN :
```bash
ssh user@10.10.0.2
```

- Connexion à un serveur web local depuis le VPS (reverse proxy possible) :
```bash
curl http://10.10.0.2:80
```

- Montage d’un partage NFS/Samba entre les deux machines via VPN
- Accès distant à des bases de données internes :
```bash
psql -h 10.10.0.2 -U dbuser -d mydatabase
```

---

## 📌 Remarques techniques

- Les clés générées sont stockées dans `~/wireguard-keys` sur chaque machine
- Le tunnel VPN est configuré pour un subnet restreint (`/32`), mais peut être élargi au besoin pour interconnecter plusieurs réseaux LAN
- Le script suppose que l'utilisateur a les droits SSH et sudo sur les deux hôtes

---

## 🔒 Sécurité

- Les fichiers `/etc/wireguard/wg0.conf` sont protégés par `chmod 600`
- Les clés privées sont générées localement et **ne sont jamais transmises à distance**
- Les échanges sont entièrement chiffrés grâce à WireGuard

---

## 📄 Licence

Ce script est distribué librement. Vous êtes autorisé à le copier, le modifier, et l'utiliser pour des besoins personnels ou professionnels.

---

Document finalisé et relu : grammaire, titres, structure logique, et lisibilité optimisées.

