sysctl -w net.ipv4.ip_forward=1
ip addr add 10.0.200.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.200.1

ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

# (utile già ora) per raggiungere LAN1 e LAN2 passando da eFW in DMZ
ip route replace 10.200.1.0/24 via 2.80.200.2
ip route replace 10.200.2.0/24 via 2.80.200.2

