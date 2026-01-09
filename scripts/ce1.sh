sysctl -w net.ipv4.ip_forward=1
ip addr add 1.0.101.2/30 dev eth1
ip link set eth1 up
ip route replace default via 1.0.101.1

ip addr add 192.168.10.1/24 dev eth0
ip link set eth0 up

