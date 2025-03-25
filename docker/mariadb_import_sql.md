# 🐳 import-db.sh

Script Bash pour automatiser l'importation d'une base de données MySQL/MariaDB dans un conteneur Docker à partir d'un fichier `.sql`, `.sql.gz`, `.zip` ou `.tar.gz`.

---

## 📆 Fonctionnalités

- 📂 Supporte les formats :
  - `.sql`
  - `.sql.gz` (gzip)
  - `.zip` (archive contenant un fichier `.sql`)
  - `.tar.gz` / `.tgz`

- 🐫 Connexion directe à un conteneur Docker (via `DB_HOST`)
- ⚖️ Création automatique de la base de données si elle n'existe pas
- 📜 Lecture automatique des variables via `.env`
- ✍️ Création interactive du fichier `.env` si absent
- 🔍 Mode `--dry-run` pour voir la commande sans l'exécuter
- 🐨 Mode `--verbose` pour afficher chaque étape

---

## ⚖️ Prérequis

- Docker installé et fonctionnel
- Un conteneur MySQL/MariaDB en cours d’exécution
- Un fichier `.sql`, `.sql.gz`, `.zip` ou `.tar.gz` à importer

---

## 📁 Structure attendue du fichier `.env`

```env
DB_HOST=mariadb
DB_DATABASE=nom_de_la_base
DB_USERNAME=utilisateur
DB_PASSWORD=motdepasse
DB_INIT_SQL_FILE=chemin/vers/fichier.sql
```

> 💡 Si ce fichier `.env` est absent, le script vous demandera les infos de manière interactive et le générera automatiquement.

---

## 🚀 Utilisation

```bash
./import-db.sh
```

- Le script utilisera les variables définies dans `.env`
- Si des variables sont manquantes, il vous les demandera

---

### 🎠 Options disponibles

| Option       | Description                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `--verbose`  | Affiche les étapes détaillées de l’exécution                                |
| `--dry-run`  | Simule l'import sans rien exécuter (affiche la commande uniquement)         |

---

## 🥺 Exemples

### Exemple simple :
```bash
./import-db.sh
```

### Avec plus de logs :
```bash
./import-db.sh --verbose
```

### Juste pour voir ce que ferait l'import :
```bash
./import-db.sh --dry-run
```

---

## 📆 Types de fichiers supportés

| Format      | Supporté | Méthode utilisée                    |
|-------------|----------|-------------------------------------|
| `.sql`      | ✅        | Copié tel quel                      |
| `.sql.gz`   | ✅        | Décompressé avec `gunzip`           |
| `.zip`      | ✅        | Extraction via `unzip -p`           |
| `.tar.gz`   | ✅        | Extraction avec `tar -xOzf`         |

---

## 🪤 Nettoyage

Après importation, le fichier temporaire est automatiquement supprimé du conteneur (`/tmp/import-env.sql`).

---

## ❗ Sécurité

⚠️ Le mot de passe MySQL est transmis en clair dans certaines commandes internes. Ce script est destiné à un usage local ou en environnement de développement sécurisé.

---

## 📜 Licence

MIT - Tu peux l'utiliser, le modifier et le partager librement.
