# 📦 Script de Migration MariaDB

Ce script permet d'exporter automatiquement une ou plusieurs bases de données MariaDB depuis un serveur local, de les compresser, de vérifier leur intégrité, et de transférer l'archive vers un serveur distant pour restauration facultative.

---

## ✅ Fonctionnalités

- Export automatique des bases de données MySQL/MariaDB
- Compression en archive `.tar.gz`
- Génération et vérification d’un hash SHA256 pour garantir l'intégrité
- Transfert sécurisé vers serveur distant via `scp`
- Restauration automatique (optionnelle) des `.sql` sur le serveur distant
- Exécution en arrière-plan (non-bloquant)
- Mode simulation `--dry-run`

---

## ⚙️ Usage

```bash
./migration_mariadb.sh <db_user> <db_password> <remote_host> [options]
```

### 🔢 Paramètres requis

- `db_user` : utilisateur MariaDB
- `db_password` : mot de passe MariaDB
- `remote_host` : utilisateur@host SSH du serveur distant

---

## 🧩 Options disponibles

| Option                | Description                                                                 |
|------------------------|------------------------------------------------------------------------------|
| `--no-blocking`        | Exécute le script en arrière-plan                                           |
| `--dry-run`            | Simule toutes les étapes sans les exécuter réellement                      |
| `--path=/chemin`       | Spécifie le chemin distant où placer l'archive (par défaut `~`)            |
| `--restore`            | Lance la restauration automatique des `.sql` sur le serveur distant        |
| `--db=nom`             | Exporte uniquement la base de données spécifiée                            |

---

## 🧪 Exemples

### ➤ Export complet et restauration dans `/var/backups`
```bash
./migration_mariadb.sh root secret user@192.168.1.10 --path=/var/backups --restore
```

### ➤ Export uniquement de la base `app_db` sans restauration
```bash
./migration_mariadb.sh root secret user@192.168.1.10 --db=app_db
```

### ➤ Simulation complète (aucune action réelle)
```bash
./migration_mariadb.sh root secret user@192.168.1.10 --dry-run --db=app_db
```

### ➤ Lancement en arrière-plan
```bash
./migration_mariadb.sh root secret user@192.168.1.10 --no-blocking --restore
```

---

## 🔒 Vérification d'intégrité

Après transfert, le fichier `.sha256` est utilisé pour valider l’intégrité de l’archive compressée sur le serveur distant.  
Si la vérification échoue, la migration est annulée.

---

## 📜 Logs

Toutes les étapes sont enregistrées dans un fichier :
```text
./migration_db.log
```

---

## 🧹 Nettoyage

Après succès :
- Les fichiers `.tar.gz`, `.sha256` et le dossier temporaire local sont supprimés.
- Les fichiers transférés sont aussi nettoyés après décompression côté serveur.

---

## 🧑‍💻 Auteur

Script développé pour simplifier et fiabiliser les transferts de bases MariaDB entre serveurs.

---

## 🏁 Licence

MIT
