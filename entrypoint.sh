#!/bin/bash
set -eo pipefail

# verify variables
if [ -z "$S3_ACCESS_KEY" -o -z "$S3_SECRET_KEY" -o -z "$S3_URL" -o -z "$MONGO_URL" -o -z "$MONGO_USER" -o -z "$MONGO_PASSWORD" ]; then
	echo >&2 'Backup information is not complete. You need to specify S3_ACCESS_KEY, S3_SECRET_KEY, S3_URL, MONGO_URL, MONGO_USER, MONGO_PASSWORD. No backups, no fun.'
	exit 1
fi

# set s3 config
sed -i "s|%%S3_ACCESS_KEY%%|$S3_ACCESS_KEY|g" /root/.s3cfg
sed -i "s|%%S3_SECRET_KEY%%|$S3_SECRET_KEY|g" /root/.s3cfg

# verify S3 config
s3cmd ls "s3://$S3_URL" > /dev/null

# set cron schedule TODO: check if the string is valid (five or six values separated by white space)
[[ -z "$CRON_SCHEDULE" ]] && CRON_SCHEDULE='0 2 * * *' && \
echo "CRON_SCHEDULE set to default ('$CRON_SCHEDULE')"

# add a cron job
echo "$CRON_SCHEDULE root rm -rf /tmp/dump && mongodump -h '$MONGO_URL' -u '$MONGO_USER' -p '$MONGO_PASSWORD' --out /tmp/dump/ --gzip >> /var/log/cron.log 2>&1 && s3cmd sync /tmp/dump s3://$S3_URL/ >> /var/log/cron.log 2>&1 && rm -rf /tmp/dump" >> /etc/crontab
crontab /etc/crontab

exec "$@"
