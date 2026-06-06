# Backup & Restore

Aster stores all persistent data in two Docker volumes. Regular backups are especially important before updates and in production environments.

## Volume Overview

| Volume | Contents |
|---|---|
| `aster-db-data` | PostgreSQL database (chats, agents, configuration, users) |
| `aster-sources` | Namespace rule files (memory policies, configuration) |

---

## Backup

### Database Backup (SQL Dump)

```bash
docker exec aster-db pg_dump -U postgres aster > backup-$(date +%Y%m%d).sql
```

Compressed backup:

```bash
docker exec aster-db pg_dump -U postgres aster | gzip > backup-$(date +%Y%m%d).sql.gz
```

### Namespaces Volume

```bash
docker run --rm \
  -v aster-sources:/data \
  -v "$(pwd)/backups:/backup" \
  alpine tar czf /backup./sources-$(date +%Y%m%d).tar.gz /data
```

### Full Backup Script

```bash
#!/bin/bash
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Database
docker exec aster-db pg_dump -U postgres aster \
  > "$BACKUP_DIR/aster-db-${TIMESTAMP}.sql"
echo "✓ DB backup: $BACKUP_DIR/aster-db-${TIMESTAMP}.sql"

# Namespaces volume
docker run --rm \
  -v aster-sources:/data \
  -v "$(pwd)/backups:/backup" \
  alpine tar czf "/backup/sources-${TIMESTAMP}.tar.gz" /data
echo "✓ Namespaces backup: $BACKUP_DIR/sources-${TIMESTAMP}.tar.gz"
```

### Recommendation: Cron Job

Automated daily backup (Linux crontab):

```
# Every day at 03:00
0 3 * * * cd /opt/aster && bash scripts/backup.sh >> /var/log/aster-backup.log 2>&1
```

---

## Restore

### Restore Database

> **Warning:** This overwrites all current data in the database.

```bash
# Stop services
docker compose stop host webui

# Drop and recreate database
docker exec -i aster-db psql -U postgres -c "DROP DATABASE IF EXISTS aster;"
docker exec -i aster-db psql -U postgres -c "CREATE DATABASE aster;"
docker exec -i aster-db psql -U postgres aster < backup-20240101.sql

# Re-run migrations (ensures schema consistency)
docker compose up -d migrator
docker compose wait migrator

# Start services again
docker compose up -d
```

From a compressed backup:

```bash
gunzip -c backup-20240101.sql.gz | docker exec -i aster-db psql -U postgres aster
```

### Restore Namespaces Volume

```bash
docker run --rm \
  -v aster-sources:/data \
  -v "$(pwd)/backups:/backup" \
  alpine sh -c "rm -rf /data/* && tar xzf /backup./sources-20240101.tar.gz -C / --strip-components=1"
```

---

## Backup Before Updates

The `update.sh` script automatically creates a backup before every update:

```bash
bash scripts/update.sh
```

Backups are stored in the `./backups/` directory.

---

## Notes

- **Back up your `.env` file:** It contains all secrets (SESSION_SECRET, DB passwords, API keys). Store it separately and encrypted.
- **Test your backups:** Regularly perform a restore on a test instance to verify backups are valid.
- **Off-site storage:** Copy backups to external storage (S3, NFS, USB) — backups in the same directory do not protect against server loss.
