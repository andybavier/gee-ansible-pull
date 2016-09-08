#!/bin/sh

# schedule is fed directly to cron
SCHEDULE='*/5 * * * *'

# User to run ansible-pull as from cron
CRON_USER=root

# File that ansible will use for logs
LOGFILE=/var/log/ansible-pull.log

# Directory to where repository will be cloned
WORKDIR=/var/lib/ansible/local

# Repository to check out
# repo must contain a local.yml file at top level
REPO_URL=git://github.com/andybavier/gee-ansible-pull.git
REPO_BRANCH=devel

apt-get update
apt-get install -y software-properties-common git python-pip
add-apt-repository -y ppa:ansible/ansible
apt-get update
apt-get install -y ansible

pip install Flask
pip install -U flask-cors
pip install flask-restful

mkdir -p $WORKDIR
chown root:root $WORKDIR
chmod 0751 $WORKDIR

# Create crontab entry to clone/pull git repository
cat <<EOF > /etc/cron.d/ansible-pull
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

$SCHEDULE $CRON_USER ansible-pull -o -d $WORKDIR --accept-host-key -U $REPO_URL -C $REPO_BRANCH >>$LOGFILE 2>&1
EOF
chown root:root /etc/cron.d/ansible-pull
chmod 0644 /etc/cron.d/ansible-pull

# Create logrotate entry for ansible-pull.log
cat <<EOF > /etc/logrotate.d/ansible-pull
$LOGFILE {
  rotate 7
  daily
  compress
  missingok
  notifempty
}
EOF
chown root:root /etc/logrotate.d/ansible-pull
chmod 0644 /etc/logrotate.d/ansible-pull
