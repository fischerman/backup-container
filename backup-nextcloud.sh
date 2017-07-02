#!/bin/bash

set -e

kubectl exec $NEXTCLOUD_POD -- sudo -u www-data /var/www/html/occ maintenance:mode --on
pg_dump $PGDATABASE > /backup-staging/db.sql
rsync -av --delete /app-data /backup-staging
kubectl exec $NEXTCLOUD_POD -- sudo -u www-data /var/www/html/occ maintenance:mode --off
# rdiff-backup remote

# PGDATABASE
# PGHOST
# PGOPTIONS
# PGPORT
# PGUSER