ip addr add 10.200.1.13/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.2

