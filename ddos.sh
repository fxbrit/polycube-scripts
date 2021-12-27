#!/bin/bash

function cleanup {

    set +e

    # delete cubes
    polycubectl del br1client
    polycubectl del r1

    # delete virtual links
    sudo ip link del veth1root
    sudo ip link del veth2root
    sudo ip link del veth_srv_root

    # delete namespaces
    sudo ip netns del ns1
    sudo ip netns del ns2

    # delete routes
    sudo ip route del 10.10.7.0/24 via 10.10.8.254
    sudo ip route del 10.11.11.0/24 via 10.10.8.254

    # reset SYN cookies
    sudo sysctl -w net.ipv4.tcp_syncookies=1
  
}
trap cleanup EXIT

set -x
set -e

# create namespace1, namespace2 and br1 as in router-nat
sudo ip netns add ns1
sudo ip link add veth1root type veth peer name veth1ns
sudo ip link set veth1ns netns ns1
sudo ip netns exec ns1 ip link set dev veth1ns up
sudo ip link set dev veth1root up
sudo ip netns exec ns1 ip addr add 10.10.7.1/24 dev veth1ns
sudo ip netns exec ns1 ip route add default via 10.10.7.254 dev veth1ns
sudo ip netns add ns2
sudo ip link add veth2root type veth peer name veth2ns
sudo ip link set veth2ns netns ns2
sudo ip netns exec ns2 ip link set dev veth2ns up
sudo ip link set dev veth2root up
sudo ip netns exec ns2 ip addr add 10.10.7.2/24 dev veth2ns
sudo ip netns exec ns2 ip route add default via 10.10.7.254 dev veth2ns
polycubectl simplebridge add br1client
polycubectl br1client ports add toveth1
polycubectl connect br1client:toveth1 veth1root
polycubectl br1client ports add toveth2
polycubectl connect br1client:toveth2 veth2root

# connect bridge to router
polycubectl br1client ports add to_router
polycubectl router add r1
polycubectl r1 ports add to_br1client ip=10.10.7.254/24
polycubectl connect r1:to_br1client br1client:to_router

# create and activate link that will be used to connect root namespace and router
sudo ip link add veth_srv_root type veth peer name veth_srv_router
sudo ip link set dev veth_srv_root up
sudo ip link set dev veth_srv_router up
sudo ip addr add 10.10.8.1/24 dev veth_srv_root

# make client namespaces reachable from root through the router
sudo ip route add 10.10.7.0/24 via 10.10.8.254

# add route from which we will be attacking
sudo ip route add 10.11.11.0/24 via 10.10.8.254

# connect router to root namespace
polycubectl r1 ports add to_server ip=10.10.8.254/24
polycubectl connect r1:to_server veth_srv_router

# disable SYN cookies as we want to simulate SYN flooding
sudo sysctl -w net.ipv4.tcp_syncookies=0

# add ddos mitigator
polycubectl ddosmitigator add ddm1
polycubectl attach ddm1 veth_srv_root

# blacklist IPs that are used for attack
for i in `seq 0 255`; do
    polycubectl ddm1 blacklist-src add 10.11.11.${i}
    echo "Blackisting address 10.11.11.${i}"
done

read -p "press ENTER to delete current config."
