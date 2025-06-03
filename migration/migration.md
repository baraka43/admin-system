# 📦 Script de Migration Automatique

Ce script Bash permet de migrer un dossier local vers un serveur distant via SSH, avec compression, vérification d'intégrité, gestion des permissions, exécution en arrière-plan, et simulation à sec.

---

## ✅ Fonctionnalités principales

- Compression d'un dossier local au format `.tar.gz`
- Génération d'un hash SHA256 pour garantir l'intégrité
- Transfert sécurisé de l'archive via `scp`
- Vérification du hash côté serveur avant décompression
- Dossier de destination personnalisable avec `--path`
- Exécution en arrière-plan via `--no-blocking`
- Mode simulation (`--dry-run`) pour tester sans exécuter
- Gestion des permissions sur le dossier distant
- Logging détaillé dans `migration.log`

---

## 📁 Arborescence des fichiers

```
.
├── migration            # Script Bash
├── migration.log        # Fichier de log généré automatiquement
├── README.md            # Ce fichier de documentation
```

---

## 🔧 Prérequis

- Linux/macOS avec accès à `bash`, `scp`, `tar`, `sha256sum`
- Clé SSH fonctionnelle pour se connecter au serveur distant
- Droits en écriture sur le dossier distant (ou accès `sudo`)

---

## 🚀 Utilisation de base

```bash
./migration <nom_dossier> <user@host> [options]
```

**Exemple minimal :**

```bash
./migration mon_site user@192.168.1.100
```

Cela compresse le dossier `mon_site`, l’envoie vers `/var/www/` du serveur, vérifie l’intégrité, le décompresse, puis nettoie l’archive locale et distante.

---

## ⚙️ Options disponibles

| Option                | Description                                                                 |
|------------------------|------------------------------------------------------------------------------|
| `--force`              | Supprime le dossier distant s’il existe déjà                                 |
| `--only-transfer`      | Transfère uniquement l’archive sans décompression                            |
| `--path=/chemin`       | Spécifie un dossier de destination différent de `/var/www`                   |
| `--no-blocking`        | Exécute le script en arrière-plan (non bloquant)                             |
| `--dry-run`            | Simule toutes les opérations sans les exécuter réellement                    |

---

## 🧪 Cas d'utilisation pratiques

### 🔁 Migration complète avec décompression
```bash
./migration app user@192.168.1.100 --path=/var/www/html --force
```

### 📂 Transfert uniquement (pas de décompression)
```bash
./migration backup user@192.168.1.100 --only-transfer --path=/mnt/backups
```

### 🧪 Test en simulation
```bash
./migration test_dir user@192.168.1.100 --path=/tmp/migration --dry-run
```

### ⏱ Migration silencieuse en arrière-plan
```bash
./migration data user@192.168.1.100 --no-blocking --force
```

---

## 🔐 Gestion des permissions distantes

Le script vérifie si le dossier distant est accessible en écriture. Si ce n’est pas le cas et si l’utilisateur a les droits (root ou sudo), il tente de corriger automatiquement avec `chmod`.

---

## 📜 Fichier `migration.log`fs


Toutes les actions importantes sont enregistrées avec horodatage :

```log
2025-03-24 20:00:01 | 🚀 DÉBUT MIGRATION: mon_site vers user@192.168.1.100:/var/www
2025-03-24 20:00:02 | 📦 Compression de 'mon_site' → 'mon_site_20250324_200002.tar.gz'...
2025-03-24 20:00:03 | 🔐 Génération du hash SHA256...
2025-03-24 20:00:04 | 🚀 Transfert de l’archive vers user@host:/var/www ...
2025-03-24 20:00:06 | 🔍 Vérification SHA256 réussie : fichier intact.
2025-03-24 20:00:08 | ✅ FIN MIGRATION: mon_site
```

---

## 🧹 Nettoyage automatique

- Suppression de l’archive `.tar.gz` locale et distante
- Suppression du fichier `.sha256`

---

## 🧬 Intégrité assurée (SHA256)

- Génération automatique d’un fichier `.sha256` localement
- Transfert du fichier avec l’archive
- Vérification côté serveur
- La migration échoue si le fichier est altéré en transit

---

## 🏁 Licence

MIT

---

## 🧑‍💻 Auteur

Développé par [TonNom / TonÉquipeDevOps] pour automatiser et sécuriser les déploiements distants via SSH.
