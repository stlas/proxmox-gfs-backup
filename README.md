# Proxmox VE GFS Backup Manager

Ein Backup-Management-Tool für Proxmox VE, das LXC-Container-Backups nach dem GFS (Grandfather-Father-Son) Rotationsschema verwaltet.

## Funktionen

- Automatische Verwaltung von LXC-Container-Backups
- GFS (Grandfather-Father-Son) Rotationsschema
- Konfigurierbare Aufbewahrungszeiten für:
  - Tägliche Backups
  - Wöchentliche Archivierung
  - Monatliche Langzeitarchivierung
- Dry-Run Modus für sichere Überprüfung
- Ausführliches Logging
- Automatische Erkennung von Backup-Speichern

## Installation

1. Laden Sie das Skript herunter:
   ```bash
   wget -O /root/gfs_backup_manager.sh https://raw.githubusercontent.com/stlas1967/proxmox-gfs-backup/main/gfs_backup_manager.sh
   ```

2. Machen Sie es ausführbar:
   ```bash
   chmod +x /root/gfs_backup_manager.sh
   ```

## Konfiguration

Bearbeiten Sie die folgenden Variablen am Anfang des Skripts:

```bash
DAILY_RETENTION_DAYS="8"     # Aufbewahrungsdauer für tägliche Backups
WEEKLY_RETENTION_WEEKS="12"   # Aufbewahrungsdauer für wöchentliche Archivierung
MONTHLY_RETENTION_MONTHS="12" # Aufbewahrungsdauer für monatliche Archivierung
DRY_RUN="1"                  # 1: Nur simulieren, 0: Tatsächlich ausführen
```

## Verwendung

### Manuelle Ausführung

```bash
/root/gfs_backup_manager.sh
```

### Als Cron-Job einrichten

Fügen Sie folgende Zeile zu Ihrem Crontab hinzu (führt das Skript täglich um 2:30 Uhr aus):

```bash
30 2 * * * /root/gfs_backup_manager.sh > /var/log/lxc_backup_cleanup_cron.log 2>&1
```

## Logging

Das Skript protokolliert alle Aktionen in zwei Dateien:
- `/var/log/lxc_backup_cleanup.log`: Hauptprotokoll
- `/var/log/lxc_backup_cleanup_cron.log`: Cron-Job-Ausgabe

## Anforderungen

- Proxmox VE 7.0 oder höher
- Bash
- Standardbefehle: awk, date
- Proxmox-Befehle: pct, pvesm

## Sicherheit

- Verwenden Sie immer zuerst den Dry-Run Modus (DRY_RUN="1")
- Erstellen Sie ein Backup Ihrer Daten vor der ersten Verwendung
- Überprüfen Sie die Logs nach jeder Ausführung

## Lizenz

MIT License

## Autor

Stefan Laszczyk

## Mitwirken

Beiträge sind willkommen! Bitte erstellen Sie einen Pull Request oder ein Issue auf GitHub.
