# 📦 Scripts de migration de fichiers et bases de données

Ce projet contient **deux scripts Bash puissants** permettant de migrer efficacement des fichiers applicatifs ou des bases de données **MariaDB** entre serveurs via SSH, avec journalisation, compression, vérification d’intégrité et restauration.

---

## 1. `migration.sh` – Migration de dossiers

Ce script permet de compresser un dossier local, le transférer sur un serveur distant, vérifier l'intégrité avec un hash SHA256, et le décompresser à destination.

### Fonctionnalités :

- Compression `tar.gz` automatique
- Vérification SHA256 post-transfert
- Journalisation (`migration.log`)
- Exécution en arrière-plan (`--no-blocking`)
- Transfert seul (`--only-transfer`)
- Destination personnalisée (`--path=/chemin`)
- Option `--force` pour écraser les données distantes
- Permissions corrigées automatiquement si possible

### Exemple :

```bash
./migration.sh dossier user@host --path=/var/www --force --no-blocking
```

---

## 2. `migration_mariadb.sh` – Migration de bases MariaDB

Ce script exporte les bases de données locales en fichiers `.sql`, les compresse et les transfère vers un serveur distant, avec possibilité de restauration automatique.

### Fonctionnalités :

- Export `.sql` avec `mysqldump`
- Support du mode **parallèle** pour gagner du temps (`--parallel`, `--parallel-limit`)
- Restauration automatique (`--restore`)
- Export d’une seule base (`--db=nom`)
- Compression + vérification SHA256
- Journalisation configurable (`--log=...`)
- Mode simulation (`--dry-run`)
- Exécution non bloquante (`--no-blocking`)

### Exemple :

```bash
./migration_mariadb.sh root motdepasse user@host --parallel --parallel-limit=4 --path=/backup/sql --restore
```

---

## 🗂️ Arborescence type

```
.
├── migration.sh
├── migration_mariadb.sh
├── migration.log
├── db_backup_20250324_154210/
│   ├── ma_base.sql
│   └── ...
```

---

## 📘 Prérequis

- Connexion SSH fonctionnelle entre les serveurs
- Droits `mysqldump` sur les bases à exporter
- Outils : `bash`, `tar`, `sha256sum`, `scp`

---
# import-db.sh — Script d'importation SQL Docker

Script bash pour importer automatiquement un fichier `.sql`, `.sql.gz`, `.zip` ou `.tar.gz` dans une base MariaDB/MySQL dans Docker.

## Usage rapide
```bash
./import-db.sh [--verbose] [--dry-run]
```

## Fonctionnalités
- Chargement auto des variables depuis `.env`
- Création interactive du `.env` si absent
- Support des formats compressés (`.gz`, `.zip`, `.tar.gz`)
- Création auto de la base si absente
- Import via `source` dans le conteneur Docker

## Variables nécessaires
Dans `.env` ou demandées :
```
DB_HOST=db
DB_DATABASE=ma_base
DB_USERNAME=root
DB_PASSWORD=secret
DB_INIT_SQL_FILE=dump.sql.gz
```

## Exemples
```bash
./import-db.sh                     # Exécution normale
./import-db.sh --verbose          # Affiche les étapes
./import-db.sh --dry-run          # Simule l'import
```

## Licence
MIT



# 🐳 export-db.sh — Version synthétique

Script Bash pour exporter une base MariaDB/MySQL depuis un conteneur Docker.

## ⚙️ Commande
```bash
./export-db.sh [--verbose] [--dry-run] [--compress]
```

## 🔧 Prérequis `.env`
```env
DB_HOST=mariadb
DB_DATABASE=ma_base
DB_USERNAME=root
DB_PASSWORD=secret
```

## 🚀 Options
| Option       | Effet                                          |
|--------------|------------------------------------------------|
| `--verbose`  | Affiche les étapes détaillées                  |
| `--dry-run`  | Affiche la commande sans l'exécuter            |
| `--compress` | Génère un fichier `.sql.gz` au lieu de `.sql` |

## 📄 Exemple de fichier généré
```bash
ma_base_20250325_174201.sql.gz
```

## 🔐 Remarque
⚠️ Mot de passe transmis en clair. Usage local uniquement.

## 📝 Licence
MIT



Pour toute amélioration ou signalement d'anomalie, ouvrez une issue ou une pull request.

