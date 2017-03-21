#!/bin/sh

modprobe nf_tproxy_core
modprobe xt_TPROXY
modprobe xt_socket
modprobe xt_comment

ip rule add fwmark 0x01/0x01 table 300
ip route add local 0.0.0.0/0 dev lo table 300

iptables -t mangle -F
iptables -t mangle -X

iptables -t mangle -N REDWOOD
iptables -t mangle -A PREROUTING -p tcp -m socket -j REDWOOD
iptables -t mangle -A REDWOOD -j MARK --set-mark 1
iptables -t mangle -A REDWOOD -j ACCEPT
iptables -t mangle -A REDWOOD -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A REDWOOD -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A REDWOOD -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A REDWOOD -d 192.168.0.0/16 -j RETURN

iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3000
iptables -t mangle -A PREROUTING -p tcp --dport 443 -j TPROXY --tproxy-mark 0x1/0x1 --on-port 3020

#iptables -t mangle -D PREROUTING -p tcp --dport 443 -j TPROXY
