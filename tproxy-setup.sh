#!/bin/sh

modprobe nf_tproxy_core
modprobe xt_TPROXY
modprobe xt_socket
modprobe xt_comment

ip rule add fwmark 0x01/0x01 table 300
ip route add local 0.0.0.0/0 dev lo table 300

iptables -t mangle -F REDWOOD
#iptables -t mangle -D OUTPUT -j REDWOOD
iptables -t mangle -F
iptables -t mangle -X

iptables -t mangle -N REDWOOD
iptables -t mangle -A PREROUTING -p tcp -m socket -j REDWOOD
#iptables -t mangle -I OUTPUT 1 -j REDWOOD
iptables -t mangle -A REDWOOD -j MARK --set-mark 1
iptables -t mangle -A REDWOOD -j ACCEPT
iptables -t mangle -A REDWOOD -d 127.0.0.0/8 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -s 192.168.2.1 --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3021
iptables -t mangle -A PREROUTING -p tcp -s 192.168.2.1 --dport 443 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3022


# Test in linux local this ( test ok in -t nat redirect but not ok for tproxy):
# the 192.168.2.1 is a invalid ip
# ip address add 192.168.2.1/24 dev eth0
# curl --interface 192.168.2.1 http://116.10.187.30

