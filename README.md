# Proxmox GFS Backup Manager

[Deutsche Version](#deutsche-version) | [English Version](#english-version)

## Deutsche Version

Ein Bash-Skript zur Verwaltung von Backups in Proxmox VE mit GFS (Grandfather-Father-Son) Rotationsstrategie.

### Voraussetzungen

- Proxmox VE Installation
- Root-Zugriff oder Benutzer mit entsprechenden Rechten
- Bash Shell
- Ausreichend Speicherplatz für Backups unter /var/lib/vz/dump
- Mail-Server für Fehlerbenachrichtigungen (optional)

### Funktionen

- Automatische Backup-Erstellung für LXC Container und QEMU VMs
- Konfigurierbare tägliche Backup-Frequenz
- GFS Rotationsstrategie für Backup-Verwaltung
- Trockenlauf-Modus für sichere Tests
- Mehrsprachige Unterstützung (Deutsch/Englisch)
- E-Mail-Benachrichtigungen bei Fehlern
- Automatische Bereinigung alter Backups
- Anzeige der VM- und Container-Namen in allen Meldungen
- Separate Backup-Typen für VMs (vzdump-qemu-*) und Container (vzdump-lxc-*)
- Detaillierte Protokollierung aller Aktionen (stderr)
- Externe Konfigurationsdatei für einfache Anpassungen

### Konfiguration

Die Konfiguration erfolgt in der Datei `config.sh`:

Benutzerkonfiguration:
```bash
LANG="DE"                     # DE: Deutsch, EN: Englisch (Standard: EN)
NOTIFICATION_EMAIL=""         # E-Mail-Adresse für Fehlerbenachrichtigungen
DAILY_RETENTION_DAYS="8"      # Aufbewahrungsdauer für tägliche Backups
WEEKLY_RETENTION_WEEKS="12"   # Aufbewahrungsdauer für wöchentliche Backups
MONTHLY_RETENTION_MONTHS="12" # Aufbewahrungsdauer für monatliche Backups
BACKUP_FREQUENZ_TAG="1"       # Maximale Anzahl der Backups pro Tag
DRY_RUN="0"                   # 1: Nur Simulation, 0: Tatsächliche Ausführung
```

Systemkonfiguration (nur bei Bedarf anpassen):
```bash
BACKUP_DIR="/var/lib/vz/dump"
LOG_FILE="/opt/community-scripts/log/backup_cleanup.log"
DATE_FORMAT="%Y_%m_%d"
```

### Verwendung

1. Klonen Sie das Repository:
   ```bash
   git clone https://github.com/stlas/proxmox-gfs-backup.git
   ```

2. Konfigurieren Sie das Skript:
   ```bash
   # Öffnen Sie die Konfigurationsdatei
   nano config.sh

   # Passen Sie die Einstellungen an Ihre Bedürfnisse an
   LANG="DE"                     # Für deutsche Ausgaben
   NOTIFICATION_EMAIL="ihr.name@domain.com"  # Für Fehlerbenachrichtigungen
   ```

3. Machen Sie die Skripte ausführbar:
   ```bash
   chmod +x gfs_backup_manager.sh config.sh
   ```

4. Führen Sie das Skript aus:
   ```bash
   ./gfs_backup_manager.sh
   ```

5. Für automatische Ausführung, fügen Sie folgenden Crontab-Eintrag hinzu:
   ```bash
   # Öffnen Sie den Crontab-Editor
   crontab -e

   # Fügen Sie diese Zeile hinzu (Ausführung täglich um 02:30 Uhr):
   30 2 * * * /pfad/zu/gfs_backup_manager.sh > /var/log/gfs_backup_manager.log 2>&1
   ```

[Rest of German content as before...]

## English Version

A bash script for managing backups in Proxmox VE using GFS (Grandfather-Father-Son) rotation strategy.

### Prerequisites

- Proxmox VE installation
- Root access or user with appropriate permissions
- Bash shell
- Sufficient storage space under /var/lib/vz/dump
- Mail server for error notifications (optional)

### Features

- Automatic backup creation for LXC containers and QEMU VMs
- Configurable daily backup frequency
- GFS rotation strategy for backup management
- Dry-run mode for safe testing
- Multilingual support (German/English)
- Email notifications for errors
- Automatic cleanup of old backups
- Display of VM and container names in all messages
- Separate backup types for VMs (vzdump-qemu-*) and containers (vzdump-lxc-*)
- Detailed logging of all actions (stderr)
- External configuration file for easy customization

### Configuration

Configuration is done in the `config.sh` file:

User configuration:
```bash
LANG="DE"                     # DE: German, EN: English (default: EN)
NOTIFICATION_EMAIL=""         # Email address for error notifications
DAILY_RETENTION_DAYS="8"      # Retention period for daily backups
WEEKLY_RETENTION_WEEKS="12"   # Retention period for weekly backups
MONTHLY_RETENTION_MONTHS="12" # Retention period for monthly backups
BACKUP_FREQUENZ_TAG="1"       # Maximum number of backups per day
DRY_RUN="0"                   # 1: Simulation only, 0: Actual execution
```

System configuration (modify only if needed):
```bash
BACKUP_DIR="/var/lib/vz/dump"
LOG_FILE="/opt/community-scripts/log/backup_cleanup.log"
DATE_FORMAT="%Y_%m_%d"
```

### Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/stlas/proxmox-gfs-backup.git
   ```

2. Configure the script:
   ```bash
   # Open the configuration file
   nano config.sh

   # Adjust settings according to your needs
   LANG="EN"                     # For English output
   NOTIFICATION_EMAIL="your.name@domain.com"  # For error notifications
   ```

3. Make the scripts executable:
   ```bash
   chmod +x gfs_backup_manager.sh config.sh
   ```

4. Run the script:
   ```bash
   ./gfs_backup_manager.sh
   ```

5. For automatic execution, add this crontab entry:
   ```bash
   # Open the crontab editor
   crontab -e

   # Add this line (execution daily at 02:30):
   30 2 * * * /path/to/gfs_backup_manager.sh > /var/log/gfs_backup_manager.log 2>&1
   ```

[Rest of English content as before...]

## Author

Stefan Laszczak ([@stlas](https://github.com/stlas))

## License

MIT License - See LICENSE file for details.
