#!/bin/sh

create_tunnel() {
    HOST=$1
    LABEL=$2

    IFACE=gre$LABEL
    IP=$( dig +short "$HOST")
    if [ "$IP" = "$MY_IP" ]
    then
	return
    fi

    ovs-vsctl add-port br-tun $IFACE
    ovs-vsctl set interface $IFACE type=gre options:remote_ip=$IP

    MY_PORT=$( ovs-vsctl get interface $IFACE ofport )
    ovs-ofctl add-flow br-tun in_port=$MY_PORT,priority=10,dl_dst="ff:ff:ff:ff:ff:ff",action=output:$DOCKER0_PORT
}

patch_bridges() { 
    ovs-vsctl add-port docker0 patch-br-tun
    ovs-vsctl set interface patch-br-tun type=patch
    ovs-vsctl set interface patch-br-tun options:peer=patch-docker0

    ovs-vsctl add-port br-tun patch-docker0
    ovs-vsctl set interface patch-docker0 type=patch
    ovs-vsctl set interface patch-docker0 options:peer=patch-br-tun
}

MY_IP=$( hostname -i )

patch_bridges

DOCKER0_PORT=$( ovs-vsctl get interface patch-docker0 ofport )
ovs-ofctl add-flow br-tun in_port=$DOCKER0_PORT,priority=20,dl_dst="ff:ff:ff:ff:ff:ff",action=all

{% for host in groups['nodes'] %}
create_tunnel {{ hostvars[host]['inventory_hostname'] }} {{ hostvars[host]['label'] }}
{% endfor %}

