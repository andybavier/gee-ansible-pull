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
    # Links are P2P - forward all incoming traffic to docker0
    ovs-ofctl add-flow br-tun in_port=$MY_PORT,priority=10,action=output:$DOCKER0_PORT
}

patch_bridges() {
    ip link add veth-docker0 type veth peer name veth-br-tun
    brctl addif docker0 veth-br-tun
    ovs-vsctl add-port br-tun veth-docker0
    ifconfig veth-docker0 up
    ifconfig veth-br-tun up
}

cleanup() {
    brctl delif docker0 veth-br-tun || true
    ovs-vsctl del-port br-tun veth-docker0 || true

    ip link del veth-docker0 || true
    ovs-vsctl del-br br-tun || true

    ovs-vsctl add-br br-tun
}

MY_IP=$( hostname -i )

cleanup
patch_bridges

DOCKER0_PORT=$( ovs-vsctl get interface veth-docker0 ofport )

{% for host in groups['nodes'] %}
create_tunnel {{ hostvars[host]['inventory_hostname'] }} {{ hostvars[host]['label'] }}
{% endfor %}
