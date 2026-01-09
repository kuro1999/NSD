vtysh -c "conf t" \
 -c "int lo" -c "ip address 1.255.0.3/32" -c "exit" \
 -c "int eth0" -c "ip address 10.0.23.2/30" -c "exit" \
 -c "int eth1" -c "ip address 10.0.13.2/30" -c "exit" \
 -c "int eth2" -c "ip address 10.0.31.1/30" -c "exit" \
 -c "end" -c "write memory"

