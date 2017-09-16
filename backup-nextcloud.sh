#!/bin/bash

set -e

kubectl exec $NEXTCLOUD_POD -- bash -c "echo '/var/www/html/occ maintenance:mode --on' > /tmp/mon.sh && chmod +x /tmp/mon.sh && runuser -u www-data /tmp/mon.sh"

START=$(date +%s.%N)
pg_dump $PGDATABASE > /backup-staging/db.sql
rsync -a --delete /app-data /backup-staging
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to copy to staging area

kubectl exec $NEXTCLOUD_POD -- bash -c "echo '/var/www/html/occ maintenance:mode --off' > /tmp/moff.sh && chmod +x /tmp/moff.sh && runuser -u www-data /tmp/moff.sh"

START=$(date +%s.%N)
rdiff-backup --remote-schema 'ssh -i /ssh/ssh-privatekey -oStrictHostKeyChecking=no -C %s rdiff-backup --server' --print-statistics /backup-staging $DEST
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to backup to remote

# PGDATABASE
# PGHOST
# PGOPTIONS
# PGPORT
# PGUSER