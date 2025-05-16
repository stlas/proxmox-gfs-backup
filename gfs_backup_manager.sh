#!/usr/bin/env bash

# Load configuration
CONFIG_FILE="$(dirname "$0")/config.sh"
if [ ! -f "$CONFIG_FILE" ] && [ -f "${CONFIG_FILE}.example" ]; then
    echo "No config file found. Copying example config..."
    cp "${CONFIG_FILE}.example" "$CONFIG_FILE"
elif [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Set defaults
LOG_LEVEL="${1:-INFO}"  # Default to INFO if not specified
TOTAL_STEPS=0
CURRENT_STEP=0

# Progress bar function
show_progress() {
    local width=50
    local progress=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((progress * width / 100))
    local empty=$((width - filled))
    printf "\rProgress: ["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%" "$progress"
    if [ "$CURRENT_STEP" -eq "$TOTAL_STEPS" ]; then
        printf "\n"
    fi
}

# Logging functions with levels
should_log() {
    local level="$1"
    case "$LOG_LEVEL" in
        DEBUG) return 0 ;;
        INFO) [[ "$level" != "DEBUG" ]] && return 0 ;;
        WARN) [[ "$level" =~ ^(WARN|ERROR)$ ]] && return 0 ;;
        ERROR) [[ "$level" == "ERROR" ]] && return 0 ;;
        *) return 1 ;;
    esac
    return 1
}

log_message() {
    local level="$1"
    local msg="$2"
    local msg_de="$3"
    
    if ! should_log "$level"; then
        return 0
    fi

    local color=""
    local prefix=""
    case "$level" in
        DEBUG) color="\e[1;35m"; prefix="[DEBUG]" ;;
        INFO)  color="\e[1;34m"; prefix="[INFO]" ;;
        WARN)  color="\e[1;33m"; prefix="[WARN]" ;;
        ERROR) color="\e[1;31m"; prefix="[ERROR]" ;;
    esac

    if [[ "$LANG" == "de_DE.UTF-8" ]]; then
        echo -e "${color}${prefix}\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "${color}${prefix}\e[0m $msg" >&2
    fi

    # Send email for errors
    if [[ "$level" == "ERROR" && -n "$NOTIFICATION_EMAIL" ]]; then
        echo -e "Error occurred in backup script on $HOSTNAME\n\nTime: $(date)\n\n${msg_de:-$msg}" | \
        mail -s "[ERROR] Backup Error" "$NOTIFICATION_EMAIL"
    fi
}

# Initialize progress counter
init_progress() {
    local vm_count=$(qm list | tail -n +2 | wc -l)
    local ct_count=$(pct list | tail -n +2 | wc -l)
    TOTAL_STEPS=$((vm_count + ct_count + 2))  # +2 for initialization and cleanup
    CURRENT_STEP=0
    show_progress
}

# Update progress
update_progress() {
    ((CURRENT_STEP++))
    show_progress
}

# Get container and VM IDs
get_container_ids() {
    pct list | tail -n +2 | tr -s ' ' | cut -d' ' -f1
}

get_vm_ids() {
    qm list | tail -n +2 | tr -s ' ' | cut -d' ' -f2
}

# Check existing backups
check_existing_backup() {
    local id="$1"
    local type="$2"
    local today=$(date +"$DATE_FORMAT")
    local prefix="vzdump-"
    
    if [ "$type" == "vm" ]; then
        prefix="vzdump-qemu-"
    else
        prefix="vzdump-lxc-"
    fi
    
    local count=$(find "$BACKUP_DIR" -name "${prefix}${id}-*${today}*" -type f | wc -l)
    
    if [ "$count" -ge "$BACKUP_FREQUENZ_TAG" ]; then
        log_message "DEBUG" \
            "Daily backup limit reached for ${type} $id" \
            "Tägliches Backup-Limit für ${type} $id erreicht"
        return 1
    fi
    return 0
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log_message "INFO" \
            "Creating backup directory: $BACKUP_DIR" \
            "Erstelle Backup-Verzeichnis: $BACKUP_DIR"
        if [ "$DRY_RUN" != "1" ]; then
            mkdir -p "$BACKUP_DIR"
        fi
    fi
}

# Perform backup
do_backup() {
    local id="$1"
    local type="$2"
    local name="$3"
    
    log_message "DEBUG" \
        "Processing ${type} $id ($name)" \
        "Verarbeite ${type} $id ($name)"
    
    # Check if container/VM exists
    if [ "$type" == "vm" ]; then
        if ! qm status "$id" &>/dev/null; then
            log_message "ERROR" \
                "VM $id does not exist!" \
                "VM $id existiert nicht!"
            return 1
        fi
    else
        if ! pct status "$id" &>/dev/null; then
            log_message "ERROR" \
                "Container $id does not exist!" \
                "Container $id existiert nicht!"
            return 1
        fi
    fi

    if ! check_existing_backup "$id" "$type"; then
        return 0
    fi

    if [ "$DRY_RUN" == "1" ]; then
        log_message "DEBUG" \
            "[DRY-RUN] Would execute: vzdump $id --compress zstd" \
            "[DRY-RUN] Würde ausführen: vzdump $id --compress zstd"
    else
        if ! vzdump "$id" --compress zstd > /dev/null 2>&1; then
            log_message "ERROR" \
                "Backup failed for ${type} $id" \
                "Backup für ${type} $id fehlgeschlagen"
            return 1
        fi
    fi
    
    update_progress
}

# Cleanup old backups
cleanup_old_backups() {
    local found_backups=false

    while IFS= read -r backup_file; do
        if [ -n "$backup_file" ]; then
            found_backups=true
            if [ "$DRY_RUN" == "1" ]; then
                log_message "DEBUG" \
                    "[DRY-RUN] Would delete: $backup_file" \
                    "[DRY-RUN] Würde löschen: $backup_file"
            else
                rm -f "$backup_file"
                log_message "DEBUG" \
                    "Deleted: $backup_file" \
                    "Gelöscht: $backup_file"
            fi
        fi
    done < <(find "$BACKUP_DIR" -name "vzdump-*" -type f -mtime +${DAILY_RETENTION_DAYS} 2>/dev/null)

    if [ "$found_backups" = false ]; then
        log_message "DEBUG" \
            "No backups found that meet deletion criteria" \
            "Keine Backups gefunden, die die Löschkriterien erfüllen"
    fi
}

# Main execution
main() {
    if [ "$DRY_RUN" == "1" ]; then
        log_message "WARN" \
            "Running in DRY-RUN mode - no actual changes will be made" \
            "Läuft im DRY-RUN Modus - es werden keine tatsächlichen Änderungen vorgenommen"
    fi

    init_progress
    create_backup_dir
    update_progress

    # Process VMs
    for vm_id in $(get_vm_ids); do
        vm_name=$(qm config "$vm_id" | grep "name:" | cut -d' ' -f2)
        if ! do_backup "$vm_id" "vm" "$vm_name"; then
            log_message "ERROR" \
                "Failed processing VM $vm_id" \
                "Verarbeitung von VM $vm_id fehlgeschlagen"
        fi
    done

    # Process Containers
    for container_id in $(get_container_ids); do
        container_name=$(pct config "$container_id" | grep "hostname:" | cut -d' ' -f2)
        if ! do_backup "$container_id" "ct" "$container_name"; then
            log_message "ERROR" \
                "Failed processing container $container_id" \
                "Verarbeitung von Container $container_id fehlgeschlagen"
        fi
    done

    cleanup_old_backups
    update_progress

    log_message "INFO" \
        "Backup process completed" \
        "Backup-Prozess abgeschlossen"
}

# Run main function
main "$@"
