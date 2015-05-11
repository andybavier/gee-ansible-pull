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
    # ovs-ofctl mod-port br-tun $IFACE noflood 

    MY_PORT=$( ovs-vsctl get interface $IFACE ofport )
    # Ethernet broadcast
    ovs-ofctl add-flow br-tun in_port=$MY_PORT,priority=10,dl_dst="ff:ff:ff:ff:ff:ff",action=output:$DOCKER0_PORT
    # IPv6 neighbor discovery
    ovs-ofctl add-flow br-tun in_port=$MY_PORT,priority=10,dl_dst="33:33:00:00:00:02",action=output:$DOCKER0_PORT
}

patch_bridges() { 
    ip link add veth-docker0 type veth peer name veth-br-tun
    brctl addif docker0 veth-br-tun
    ovs-vsctl add-port br-tun veth-docker0
    ifconfig veth-docker0 up
    ifconfig veth-br-tun up
}

MY_IP=$( hostname -i )

patch_bridges

DOCKER0_PORT=$( ovs-vsctl get interface veth-docker0 ofport )

{% for host in groups['nodes'] %}
create_tunnel {{ hostvars[host]['inventory_hostname'] }} {{ hostvars[host]['label'] }}
{% endfor %}

