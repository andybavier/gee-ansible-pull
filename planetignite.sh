#!/bin/bash

set -e

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


echo ''
echo ''
echo 'Type a single-word name for this node (and press ENTER).'
echo 'The name will be used to create the DNS entry for the node.'
echo 'E.g., "starlight" -> DNS name: "starlight.gee-project.net"'
echo ''
echo 'Node name:'

read NAME

if [[ "$NAME" =~ [^A-Za-z0-9] ]]
then
    echo 'Name should only contain alphanumeric characters, exiting...'
    exit 1
fi

echo "Installing packages..."

apt-get update
apt-get install -y software-properties-common git curl
add-apt-repository -y ppa:ansible/ansible
apt-get update
apt-get install -y ansible

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

curl -O https://raw.githubusercontent.com/rickmcgeer/geni-expt-engine/master/slice-scripts/add-node-self.py

DNSNAME=$NAME.gee-project.net
SITE=$NAME
NICKNAME=$NAME

python add-node-self.py -dnsName $DNSNAME -nickname $NICKNAME -siteName $SITE

echo ""
echo "Node $DNSNAME has been registered with the PlanetIgnite Portal."
echo "It should be provisioned and usable in the next 5 minutes."
