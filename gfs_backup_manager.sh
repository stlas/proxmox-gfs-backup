#!/usr/bin/env bash

# === Messaging Functions ===
LANG_DE=true

msg_info() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG_DE" == "true" ]]; then
        echo -e "\e[1;34m[INFO]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;34m[INFO]\e[0m $msg" >&2
    fi
}

msg_success() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG_DE" == "true" ]]; then
        echo -e "\e[1;32m[ERFOLG]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;32m[SUCCESS]\e[0m $msg" >&2
    fi
}

msg_warning() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG_DE" == "true" ]]; then
        echo -e "\e[1;33m[WARNUNG]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;33m[WARNING]\e[0m $msg" >&2
    fi
}

msg_error() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG_DE" == "true" ]]; then
        echo -e "\e[1;31m[FEHLER]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;31m[ERROR]\e[0m $msg" >&2
    fi
}

# === Configuration ===
DAILY_RETENTION_DAYS="8"
WEEKLY_RETENTION_WEEKS="12"
MONTHLY_RETENTION_MONTHS="12"
BACKUP_FREQUENZ_TAG="1"

DRY_RUN="0"
LOG_FILE="/opt/community-scripts/log/backup_cleanup.log"

# Get a list of all LXC container IDs
get_container_ids() {
    msg_info \
        "Retrieving list of LXC containers..." \
        "Hole Liste der LXC Container..." >&2
    local container_ids=$(pct list | tail -n +2 | tr -s ' ' | cut -d' ' -f1)
    msg_info \
        "Found containers: $container_ids" \
        "Gefundene Container: $container_ids" >&2
    echo "$container_ids"
}

# Get a list of all VM IDs
get_vm_ids() {
    msg_info \
        "Retrieving list of VMs..." \
        "Hole Liste der VMs..." >&2
    local vm_ids=$(qm list | tail -n +2 | tr -s ' ' | cut -d' ' -f2)
    msg_info \
        "Found VMs: $vm_ids" \
        "Gefundene VMs: $vm_ids" >&2
    echo "$vm_ids"
}

# Check if backup already exists for today
check_existing_backup() {
    local id="$1"
    local type="$2"  # 'vm' or 'ct'
    local today=$(date +%Y_%m_%d)
    local backup_dir="/var/lib/vz/dump"
    local prefix="vzdump-"
    
    if [ "$type" == "vm" ]; then
        prefix="vzdump-qemu-"
    else
        prefix="vzdump-lxc-"
    fi
    
    local count=$(find "$backup_dir" -name "${prefix}${id}-*${today}*" -type f | wc -l)
    
    if [ "$count" -ge "$BACKUP_FREQUENZ_TAG" ]; then
        msg_info \
            "Daily backup limit reached for ${type} $id" \
            "Tägliches Backup-Limit für ${type} $id erreicht"
        return 1
    fi
    return 0
}

# Create backup directory if it doesn't exist
create_backup_dir() {
    local backup_dir="/var/lib/vz/dump"
    
    if [ ! -d "$backup_dir" ]; then
        msg_info \
            "Creating backup directory: $backup_dir" \
            "Erstelle Backup-Verzeichnis: $backup_dir"
        if [ "$DRY_RUN" != "1" ]; then
            mkdir -p "$backup_dir"
        else
            msg_info \
                "[DRY-RUN] Would create directory: $backup_dir" \
                "[DRY-RUN] Würde Verzeichnis erstellen: $backup_dir"
        fi
    fi
}

# Perform the actual backup
do_backup() {
    local id="$1"
    local type="$2"  # 'vm' or 'ct'
    local name="$3"
    
    msg_info \
        "Starting backup for ${type} $id ($name)" \
        "Starte Backup für ${type} $id ($name)"
    
    # Check if container/VM exists
    if [ "$type" == "vm" ]; then
        if ! qm status "$id" &>/dev/null; then
            msg_error \
                "VM $id does not exist!" \
                "VM $id existiert nicht!"
            return 1
        fi
    else
        if ! pct status "$id" &>/dev/null; then
            msg_error \
                "Container $id does not exist!" \
                "Container $id existiert nicht!"
            return 1
        fi
    fi

    # Check if backup already exists for today
    if ! check_existing_backup "$id" "$type"; then
        return 0
    fi

    # Create the backup
    msg_info \
        "Creating backup for ${type} $id..." \
        "Erstelle Backup für ${type} $id..."
    
    if [ "$DRY_RUN" == "1" ]; then
        msg_info \
            "[DRY-RUN] Would execute: vzdump $id --compress zstd" \
            "[DRY-RUN] Würde ausführen: vzdump $id --compress zstd"
        msg_success \
            "[DRY-RUN] Backup simulation completed for ${type} $id" \
            "[DRY-RUN] Backup-Simulation für ${type} $id abgeschlossen"
    else
        if vzdump "$id" --compress zstd; then
            msg_success \
                "Backup completed successfully for ${type} $id" \
                "Backup für ${type} $id erfolgreich abgeschlossen"
        else
            msg_error \
                "Backup failed for ${type} $id" \
                "Backup für ${type} $id fehlgeschlagen"
            return 1
        fi
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    msg_info \
        "Starting cleanup of old backups..." \
        "Starte Bereinigung alter Backups..."

    local backup_dir="/var/lib/vz/dump"
    local today=$(date +%s)
    local found_backups=false

    # Find files older than DAILY_RETENTION_DAYS
    while IFS= read -r backup_file; do
        if [ -n "$backup_file" ]; then
            found_backups=true
            if [ "$DRY_RUN" == "1" ]; then
                msg_info \
                    "[DRY-RUN] Would delete: $backup_file" \
                    "[DRY-RUN] Würde löschen: $backup_file"
            else
                rm -f "$backup_file"
                msg_info \
                    "Deleted: $backup_file" \
                    "Gelöscht: $backup_file"
            fi
        fi
    done < <(find "$backup_dir" -name "vzdump-*" -type f -mtime +${DAILY_RETENTION_DAYS} 2>/dev/null)

    if [ "$found_backups" = false ]; then
        msg_info \
            "No backups found that meet deletion criteria" \
            "Keine Backups gefunden, die die Löschkriterien erfüllen"
    fi
}

# Main execution
main() {
    msg_info \
        "Starting GFS backup manager..." \
        "Starte GFS Backup Manager..."

    if [ "$DRY_RUN" == "1" ]; then
        msg_warning \
            "Running in DRY-RUN mode - no actual changes will be made" \
            "Läuft im DRY-RUN Modus - es werden keine tatsächlichen Änderungen vorgenommen"
    fi

    create_backup_dir

    # Process VMs
    msg_info \
        "Processing VMs..." \
        "Verarbeite VMs..."
    vm_ids=$(get_vm_ids)
    for vm_id in $vm_ids; do
        vm_name=$(qm config "$vm_id" | grep "name:" | cut -d' ' -f2)
        if ! do_backup "$vm_id" "vm" "$vm_name"; then
            msg_error \
                "Failed processing VM $vm_id" \
                "Verarbeitung von VM $vm_id fehlgeschlagen"
            continue
        fi
    done

    # Process Containers
    msg_info \
        "Processing Containers..." \
        "Verarbeite Container..."
    container_ids=$(get_container_ids)
    for container_id in $container_ids; do
        container_name=$(pct config "$container_id" | grep "hostname:" | cut -d' ' -f2)
        if ! do_backup "$container_id" "ct" "$container_name"; then
            msg_error \
                "Failed processing container $container_id" \
                "Verarbeitung von Container $container_id fehlgeschlagen"
            continue
        fi
    done

    # Cleanup old backups
    cleanup_old_backups

    msg_success \
        "Backup process completed" \
        "Backup-Prozess abgeschlossen"
}

# Run main function
main "$@"
