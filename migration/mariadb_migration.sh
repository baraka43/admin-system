#!/bin/bash

# === CONFIGURATION DU LOG ===
LOG_FILE="./migration_db.log"
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

progress_bar() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    echo -ne "\r$message: [${percent}%]"
}

parse_args() {
    BLOCKING=true
    DRY_RUN=false
    REMOTE_PATH="~"
    RESTORE=false
    SPECIFIC_DB=""
    PARALLEL=false
    PARALLEL_LIMIT=4
    for arg in "$@"; do
        case $arg in
            --no-blocking) BLOCKING=false ;;
            --dry-run) DRY_RUN=true ;;
            --restore) RESTORE=true ;;
            --path=*) REMOTE_PATH="${arg#*=}" ;;
            --db=*) SPECIFIC_DB="${arg#*=}" ;;
            --parallel) PARALLEL=true ;;
            --parallel-limit=*) PARALLEL_LIMIT="${arg#*=}" ;;
        esac
    done
}

export_databases() {
    mkdir -p "$BACKUP_DIR"
    log "📦 Export des bases dans le dossier $BACKUP_DIR..."
    TOTAL_DBS=$(echo "$DATABASES" | wc -w)
    COUNT=0
    DONE=0
    PIDS=()

    update_parallel_progress() {
        while [ $DONE -lt $TOTAL_DBS ]; do
            sleep 1
            progress_bar $DONE $TOTAL_DBS "⏳ Export parallèle"
        done
        echo ""
    }

    if $PARALLEL; then
        update_parallel_progress &
        PROGRESS_PID=$!
    fi

    for DB in $DATABASES; do
        COUNT=$((COUNT+1))
        if $PARALLEL; then
            (
                mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB" > "$BACKUP_DIR/${DB}.sql"
                if [ $? -ne 0 ]; then
                    log "❌ Échec de l'export de la base: $DB"
                    exit 1
                fi
                log "✅ Base $DB exportée."
                DONE=$((DONE + 1))
            ) &
            PIDS+=("$!")

            while [ $(jobs -rp | wc -l) -ge $PARALLEL_LIMIT ]; do
                sleep 1
            done
        else
            progress_bar $COUNT $TOTAL_DBS "Export ($COUNT/$TOTAL_DBS) $DB"
            mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB" > "$BACKUP_DIR/${DB}.sql"
            if [ $? -ne 0 ]; then
                echo ""
                log "❌ Échec de l'export de la base: $DB"
                exit 1
            fi
            echo ""
            log "✅ ($COUNT/$TOTAL_DBS) Base $DB exportée."
        fi
    done

    if $PARALLEL; then
        log "⏳ Attente de la fin des exports parallèles..."
        wait
        kill $PROGRESS_PID 2>/dev/null
        echo ""
        log "✅ Tous les exports parallèles terminés."
    fi
}
