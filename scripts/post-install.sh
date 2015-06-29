#!/bin/sh

# The Docker service starts automatically when installed.  This creates the
# docker0 bridge using the wrong IP address.  For some reason adding
# /etc/default/docker before installing the Docker service doesn't seem
# to work correctly.  So we'll fix the problem post-install.

service docker stop

ifconfig docker0 down || true
brctl delbr docker0 || true

service docker start
/usr/local/sbin/ovs-setup.sh
