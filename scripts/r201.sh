vtysh -c "conf t" \
 -c "int lo" -c "ip address 2.255.0.1/32" -c "exit" \
 -c "int eth0" -c "ip address 10.0.31.2/30" -c "exit" \
 -c "int eth1" -c "ip address 10.0.202.1/30" -c "exit" \
 -c "int eth2" -c "ip address 10.0.200.1/30" -c "exit" \
 -c "end" -c "write memory"

