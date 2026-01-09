vtysh -c "conf t" \
 -c "int lo" -c "ip address 1.255.0.1/32" -c "exit" \
 -c "int eth0" -c "ip address 1.0.101.1/30" -c "exit" \
 -c "int eth1" -c "ip address 10.0.12.1/30" -c "exit" \
 -c "int eth2" -c "ip address 10.0.13.1/30" -c "exit" \
 -c "end" -c "write memory"

