#!/bin/bash

function cleanup {

    set +e

    # delete cubes
    polycubectl del br1client
    polycubectl del br1server
    polycubectl del br2server
    polycubectl del r1

    # delete virtual links
    sudo ip link del veth1root
    sudo ip link del veth2root
    sudo ip link del veth3root
    sudo ip link del veth4root

    # delete namespaces
    sudo ip netns del ns1
    sudo ip netns del ns2
    sudo ip netns del ns3
    sudo ip netns del ns4

}
trap cleanup EXIT

set -x
set -e

# create namespace1, namespace 2 and br1 as in router-nat
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

# create namespace3, namespace 4 and br2 as in router-nat
sudo ip netns add ns3
sudo ip link add veth3root type veth peer name veth3ns
sudo ip link set veth3ns netns ns3
sudo ip netns exec ns3 ip link set dev veth3ns up
sudo ip link set dev veth3root up
sudo ip netns exec ns3 ip addr add 10.10.8.3/24 dev veth3ns
sudo ip netns exec ns3 ip route add default via 10.10.8.254 dev veth3ns
sudo ip netns add ns4
sudo ip link add veth4root type veth peer name veth4ns
sudo ip link set veth4ns netns ns4
sudo ip netns exec ns4 ip link set dev veth4ns up
sudo ip link set dev veth4root up
sudo ip netns exec ns4 ip addr add 10.10.8.4/24 dev veth4ns
sudo ip netns exec ns4 ip route add default via 10.10.8.254 dev veth4ns
polycubectl simplebridge add br2server
polycubectl br2server ports add toveth3
polycubectl connect br2server:toveth3 veth3root
polycubectl br2server ports add toveth4
polycubectl connect br2server:toveth4 veth4root

# create br1server
polycubectl simplebridge add br1server

# connect br1client, br1server and router
polycubectl br1client ports add to_router
polycubectl br1server ports add to_router
polycubectl router add r1
polycubectl r1 ports add to_br1client ip=10.10.7.254/24
polycubectl r1 ports add to_br1server ip=10.10.8.254/24
polycubectl connect r1:to_br1client br1client:to_router
polycubectl connect r1:to_br1server br1server:to_router

# connect br1server and br2server
polycubectl br2server ports add toveth5
polycubectl br1server ports add toveth6
polycubectl connect br2server:toveth5 br1server:toveth6

read -p "press ENTER to delete current config."