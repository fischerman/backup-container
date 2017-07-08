#!/bin/bash

set -e

kubectl exec $NEXTCLOUD_POD -- sudo -u www-data /var/www/html/occ maintenance:mode --on

START=$(date +%s.%N)
pg_dump $PGDATABASE > /backup-staging/db.sql
rsync -a --delete /app-data /backup-staging
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to copy to staging area

kubectl exec $NEXTCLOUD_POD -- sudo -u www-data /var/www/html/occ maintenance:mode --off

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