#!/usr/bin/env bash

# Load configuration
CONFIG_FILE="$(dirname "$0")/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Set defaults if not configured
LANG="${LANG:-EN}"  # Default to English if not set
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"
DAILY_RETENTION_DAYS="${DAILY_RETENTION_DAYS:-8}"
WEEKLY_RETENTION_WEEKS="${WEEKLY_RETENTION_WEEKS:-12}"
MONTHLY_RETENTION_MONTHS="${MONTHLY_RETENTION_MONTHS:-12}"
BACKUP_FREQUENZ_TAG="${BACKUP_FREQUENZ_TAG:-1}"
DRY_RUN="${DRY_RUN:-0}"
BACKUP_DIR="${BACKUP_DIR:-/var/lib/vz/dump}"
LOG_FILE="${LOG_FILE:-/opt/community-scripts/log/backup_cleanup.log}"
DATE_FORMAT="${DATE_FORMAT:-%Y_%m_%d}"
HOSTNAME="${HOSTNAME:-$(hostname)}"

# Send error notification via email
send_error_mail() {
    local subject="$1"
    local message="$2"
    if [[ -n "$NOTIFICATION_EMAIL" ]]; then
        echo -e "Error occurred in backup script on $HOSTNAME\n\nTime: $(date)\n\n$message" | \
        mail -s "[ERROR] $subject" "$NOTIFICATION_EMAIL"
    fi
}

# Messaging Functions
msg_info() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG" == "DE" ]]; then
        echo -e "\e[1;34m[INFO]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;34m[INFO]\e[0m $msg" >&2
    fi
}

msg_success() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG" == "DE" ]]; then
        echo -e "\e[1;32m[ERFOLG]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;32m[SUCCESS]\e[0m $msg" >&2
    fi
}

msg_warning() {
    local msg="$1"
    local msg_de="$2"
    if [[ "$LANG" == "DE" ]]; then
        echo -e "\e[1;33m[WARNUNG]\e[0m ${msg_de:-$msg}" >&2
    else
        echo -e "\e[1;33m[WARNING]\e[0m $msg" >&2
    fi
}

msg_error() {
    local msg="$1"
    local msg_de="$2"
    local error_msg="${msg_de:-$msg}"
    if [[ "$LANG" == "DE" ]]; then
        echo -e "\e[1;31m[FEHLER]\e[0m $error_msg" >&2
    else
        echo -e "\e[1;31m[ERROR]\e[0m $msg" >&2
    fi
    # Send email notification
    send_error_mail "Backup Error" "$error_msg"
}

[Rest of the existing script content]
