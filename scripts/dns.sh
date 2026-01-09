ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.2


