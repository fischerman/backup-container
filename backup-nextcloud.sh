#!/bin/bash

set -ex

if [ -d /backup-staging/backup ]; then
    # set to true so that it can be deleted
    btrfs property set -ts /backup-staging/backup ro true
    btrfs subvolume delete -c /backup-staging/backup
fi

kubectl exec $NEXTCLOUD_POD -- bash -c "echo '/var/www/html/occ maintenance:mode --on' > /tmp/mon.sh && chmod +x /tmp/mon.sh && runuser -u www-data /tmp/mon.sh"

START=$(date +%s.%N)
btrfs subvolume snapshot /app-data /backup-staging/backup
pg_dump $PGDATABASE > /backup-staging/backup/db.sql
btrfs property set -ts /backup-staging/backup ro true
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to copy to staging area

kubectl exec $NEXTCLOUD_POD -- bash -c "echo '/var/www/html/occ maintenance:mode --off' > /tmp/moff.sh && chmod +x /tmp/moff.sh && runuser -u www-data /tmp/moff.sh"

START=$(date +%s.%N)
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RSH="ssh -i /ssh/ssh-privatekey -oStrictHostKeyChecking=no -oBatchMode=yes" 
borg create --verbose --stats --show-rc --exclude-caches $BORG_OPTION $DEST::'nextcloud-{now}' /backup-staging/backup
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo Took $DIFF seconds to backup to remote

# PGDATABASE
# PGHOST
# PGOPTIONS
# PGPORT
# PGUSER