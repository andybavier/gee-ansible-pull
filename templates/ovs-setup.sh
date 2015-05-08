#!/bin/sh

MY_IP=$( hostname -i )

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
    ovs-ofctl mod-port br-tun $IFACE noflood
}

patch_bridges() { 
    ovs-vsctl add-port br-tun patch-ovs
    ovs-vsctl set interface patch-ovs type=patch
    ovs-vsctl set interface patch-ovs options:peer=patch-docker

    ovs-vsctl add-port br-tun patch-docker
    ovs-vsctl set interface patch-docker type=patch
    ovs-vsctl set interface patch-docker options:peer=patch-ovs
}

no_arp_flood() {
    PORT=$( ovs-vsctl get interface patch-docker ofport )
    # These rules assume that all the GRE tunnel ports are in 'noflood' mode
    ovs-ofctl add-flow br-tun in_port=$PORT,priority=20,dl_dst="ff:ff:ff:ff:ff:ff",action=all
    ovs-ofctl add-flow br-tun priority=10,dl_dst="ff:ff:ff:ff:ff:ff",action=flood
}

patch_bridges

{% for host in groups['nodes'] %}
create_tunnel {{ hostvars[host]['inventory_hostname'] }} {{ hostvars[host]['label'] }}
{% endfor %}

no_arp_flood

