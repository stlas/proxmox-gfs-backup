# Proxmox GFS Backup Manager

[Deutsche Version](#deutsche-version) | [English Version](#english-version)

## Deutsche Version

Ein Bash-Skript zur Verwaltung von Backups in Proxmox VE mit GFS (Grandfather-Father-Son) Rotationsstrategie.

### Funktionen

- Automatische Backup-Erstellung für LXC Container und QEMU VMs
- Konfigurierbare tägliche Backup-Frequenz
- GFS Rotationsstrategie für Backup-Verwaltung
- Trockenlauf-Modus für sichere Tests
- Mehrsprachige Unterstützung (Deutsch/Englisch)
- Automatische Bereinigung alter Backups

### Konfiguration

Hauptkonfigurationsvariablen:
```bash
DAILY_RETENTION_DAYS="8"     # Aufbewahrungsdauer für tägliche Backups
WEEKLY_RETENTION_WEEKS="12"   # Aufbewahrungsdauer für wöchentliche Backups
MONTHLY_RETENTION_MONTHS="12" # Aufbewahrungsdauer für monatliche Backups
BACKUP_FREQUENZ_TAG="1"      # Maximale Anzahl der Backups pro Tag
DRY_RUN="1"                  # 1: Nur Simulation, 0: Tatsächliche Ausführung
```

### Verwendung

1. Klonen Sie das Repository:
   ```bash
   git clone https://github.com/LaszloFekete/proxmox-gfs-backup.git
   ```

2. Machen Sie das Skript ausführbar:
   ```bash
   chmod +x gfs_backup_manager.sh
   ```

3. Führen Sie das Skript aus:
   ```bash
   ./gfs_backup_manager.sh
   ```

### Funktionsweise

Das Skript:
1. Identifiziert alle LXC Container und QEMU VMs
2. Erstellt Backups mit vzdump
3. Prüft die tägliche Backup-Frequenz
4. Bereinigt alte Backups nach GFS-Schema
5. Protokolliert alle Aktionen

## English Version

A bash script for managing backups in Proxmox VE using GFS (Grandfather-Father-Son) rotation strategy.

### Features

- Automatic backup creation for LXC containers and QEMU VMs
- Configurable daily backup frequency
- GFS rotation strategy for backup management
- Dry-run mode for safe testing
- Multilingual support (German/English)
- Automatic cleanup of old backups

### Configuration

Main configuration variables:
```bash
DAILY_RETENTION_DAYS="8"     # Retention period for daily backups
WEEKLY_RETENTION_WEEKS="12"   # Retention period for weekly backups
MONTHLY_RETENTION_MONTHS="12" # Retention period for monthly backups
BACKUP_FREQUENZ_TAG="1"      # Maximum number of backups per day
DRY_RUN="1"                  # 1: Simulation only, 0: Actual execution
```

### Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/LaszloFekete/proxmox-gfs-backup.git
   ```

2. Make the script executable:
   ```bash
   chmod +x gfs_backup_manager.sh
   ```

3. Run the script:
   ```bash
   ./gfs_backup_manager.sh
   ```

### How it works

The script:
1. Identifies all LXC containers and QEMU VMs
2. Creates backups using vzdump
3. Checks daily backup frequency
4. Cleans up old backups according to GFS scheme
5. Logs all actions

## License

MIT License - See LICENSE file for details.
