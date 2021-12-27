#!/bin/bash

function cleanup {

    set +e

    # delete cubes
    polycubectl del br1ns
    polycubectl del r1

    # delete virtual links
    sudo ip link del veth1root
    sudo ip link del veth2root

    # delete namespaces
    sudo ip netns del ns1
    sudo ip netns del ns2

}
trap cleanup EXIT

set -x
set -e

# create namespace1 and virtual links
sudo ip netns add ns1
sudo ip link add veth1root type veth peer name veth1ns

# connect one end to namespace and other to root, then turn on
sudo ip link set veth1ns netns ns1
sudo ip netns exec ns1 ip link set dev veth1ns up
sudo ip link set dev veth1root up

# set ip address of interface and default gateway
sudo ip netns exec ns1 ip addr add 10.10.7.1/24 dev veth1ns
sudo ip netns exec ns1 ip route add default via 10.10.7.254 dev veth1ns

# do all the above for namespace2
sudo ip netns add ns2
sudo ip link add veth2root type veth peer name veth2ns
sudo ip link set veth2ns netns ns2
sudo ip netns exec ns2 ip link set dev veth2ns up
sudo ip link set dev veth2root up
sudo ip netns exec ns2 ip addr add 10.10.7.2/24 dev veth2ns
sudo ip netns exec ns2 ip route add default via 10.10.7.254 dev veth2ns

# create bridge, add ports to it and connet the namespaces through it
polycubectl simplebridge add br1ns
polycubectl br1ns ports add toveth1
polycubectl connect br1ns:toveth1 veth1root
polycubectl br1ns ports add toveth2
polycubectl connect br1ns:toveth2 veth2root

# create port to connect bridge and router
polycubectl br1ns ports add to_router

# create router and add ports to bridge and internet:
# - router interface should be default gateway.
# - enp1s0 is the name of the physical interface connected
#   to the internet. might need to change: in case use ip addr.
polycubectl router add r1
polycubectl r1 ports add to_br1ns ip=10.10.7.254/24
polycubectl r1 ports add to_internet
polycubectl connect r1:to_br1ns br1ns:to_router
polycubectl connect r1:to_internet enp1s0

# set default route to the internet, which is IP of physical default
# gateway. might need to change: in case use ip route command.
polycubectl r1 route add 0.0.0.0/0 169.254.1.1

read -p "press ENTER to delete current config."
