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

no_arp_flood() {
    PORT=$( ovs-vsctl get interface docker0 ofport )
    # These rules assume that all the GRE tunnel ports are in 'noflood' mode
    ovs-ofctl add-flow br-tun in_port=$PORT,priority=20,dl_dst="ff:ff:ff:ff:ff:ff",action=all
    ovs-ofctl add-flow br-tun priority=10,dl_dst="ff:ff:ff:ff:ff:ff",action=flood
}

{% for host in groups['nodes'] %}
create_tunnel {{ hostvars[host]['inventory_hostname'] }} {{ hostvars[host]['label'] }}
{% endfor %}

no_arp_flood

