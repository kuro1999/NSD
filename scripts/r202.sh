sysctl -w net.ipv4.ip_forward=1
ip addr add 10.0.202.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.202.1

ip addr add 10.202.3.1/24 dev eth1
ip link set eth1 up

