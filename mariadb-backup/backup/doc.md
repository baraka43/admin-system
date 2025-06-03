# 📘 Documentation du script `mariadb_full_incr_consolidated.sh`

## 🎯 Objectif

Ce script sert à **sauvegarder une instance MariaDB** en combinant trois fonctionnalités intelligentes :

1. ✅ Sauvegarde complète (si c’est la première)
2. 🔁 Sauvegarde incrémentale (quotidienne)
3. ♻️ Consolidation automatique après 7 incrémentales

---

## 📦 Fichier `.env` (configuration)

Le script lit un fichier `.env` qui contient les paramètres sensibles :

```dotenv
DB_USER=root
DB_PASS=monMotDePasse
BACKUP_DIR=/mnt/backup
```

📌 Il est généré automatiquement au premier lancement si absent.

---

## 🔄 Fonctionnement du script

| Étape                          | Ce que le script fait                                         |
|-------------------------------|----------------------------------------------------------------|
| ✅ .env introuvable            | Il demande les infos à l’utilisateur et crée `.env`           |
| ✅ Pas de sauvegarde complète | Il crée une sauvegarde complète dans `$BACKUP_DIR/full`       |
| ✅ Incrémentale du jour absente | Il crée une nouvelle incrémentale nommée `incr-YYYY-MM-DD`    |
| ❌ Incrémentale du jour existe | Il ne fait rien                                               |
| ✅ ≥ 7 incrémentales           | Il les applique, fusionne dans une nouvelle complète, puis supprime |

---

## 📁 Arborescence de sauvegarde

```
/mnt/backup/
├── .env
├── full/                   # Sauvegarde complète active
├── incr-2025-06-01/        # Incrémentales quotidiennes
├── incr-2025-06-02/
├── ...
├── backup.log              # Journal d'activité
```

---

## 🛠️ Commandes principales utilisées

### 🔄 Sauvegarde complète :
```bash
mariabackup --backup --target-dir=full ...
```

### 🔁 Sauvegarde incrémentale :
```bash
mariabackup --backup --target-dir=incr-YYYY-MM-DD --incremental-basedir=full ...
```

### ⚙️ Préparation pour restauration :
```bash
mariabackup --prepare --target-dir=full [--incremental-dir=incr-*]
```

### 📥 Restauration finale :
```bash
systemctl stop mariadb
rsync -av full/ /var/lib/mysql/
chown -R mysql:mysql /var/lib/mysql
systemctl start mariadb
```

---

## 🧠 Exemple d’utilisation automatisée

Ajoute-le dans `cron` :

```bash
crontab -e
```

Puis ajoute :
```cron
0 2 * * * /chemin/vers/mariadb_full_incr_consolidated.sh >> /mnt/backup/backup.log 2>&1
```

Cela exécute la sauvegarde tous les jours à 2h du matin.

---

## ✅ Avantages de ce script

- 🧠 Intelligent : ne refait pas ce qui a déjà été fait
- 📦 Gère les sauvegardes complètes + incrémentales
- ♻️ Consolide automatiquement pour limiter l'encombrement
- 🧹 Supprime les anciennes incrémentales après fusion

---

*Généré le 2025-06-03*
