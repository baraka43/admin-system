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

Pour toute amélioration ou signalement d'anomalie, ouvrez une issue ou une pull request.

