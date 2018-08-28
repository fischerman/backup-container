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
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RSH="ssh -i /ssh/ssh-privatekey -oStrictHostKeyChecking=no -oBatchMode=yes" 
borg create --verbose --stats --show-rc --exclude-caches $DEST::'nextcloud-{now}' /backup-staging
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to backup to remote

# PGDATABASE
# PGHOST
# PGOPTIONS
# PGPORT
# PGUSER