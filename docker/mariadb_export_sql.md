# 🐳 export-db.sh

Script Bash pour exporter une base de données MySQL/MariaDB depuis un conteneur Docker avec options de compression, journalisation et sécurité.

---

## 📆 Fonctionnalités

- Exporte une base MySQL/MariaDB présente dans un conteneur Docker
- Génère un fichier `.sql` automatiquement nommé avec timestamp
- Compression facultative du fichier exporté en `.sql.gz` (`--compress`)
- Affichage des étapes avec `--verbose`
- Simulation de la commande avec `--dry-run`

---

## ⚖️ Prérequis

- Docker installé et fonctionnel
- Conteneur MariaDB/MySQL démarré (`DB_HOST`)
- Fichier `.env` présent avec les variables suivantes :

```env
DB_HOST=mariadb
DB_DATABASE=ma_base
DB_USERNAME=root
DB_PASSWORD=secret
```

> ⚠️ Si `.env` est absent, le script refusera de s'exécuter.

---

## 🚀 Utilisation

```bash
./export-db.sh [--verbose] [--dry-run] [--compress]
```

### Options disponibles

| Option       | Description                                                              |
|--------------|---------------------------------------------------------------------------|
| `--verbose`  | Affiche les étapes détaillées pendant l'exécution                         |
| `--dry-run`  | Simule l'export sans exécution réelle (affiche la commande)              |
| `--compress` | Comprime automatiquement le fichier `.sql` exporté en `.sql.gz`          |

---

## 🧪 Exemples d'utilisation

### Export standard non compressé
```bash
./export-db.sh
```

### Export avec journalisation
```bash
./export-db.sh --verbose
```

### Export compressé
```bash
./export-db.sh --compress
```

### Simulation (dry-run)
```bash
./export-db.sh --dry-run
```

---

## 🔍 Fichier généré

- Le fichier SQL sera nommé :
  ```
  ma_base_20250325_174201.sql
  ```
- Si l'option `--compress` est activée :
  ```
  ma_base_20250325_174201.sql.gz
  ```

---

## 🛡️ Sécurité

- Le mot de passe est transmis temporairement en clair dans la commande
- Script à utiliser uniquement en environnement local ou de développement

---

## 📄 Licence

MIT — Libre d'utilisation, de modification et de redistribution.