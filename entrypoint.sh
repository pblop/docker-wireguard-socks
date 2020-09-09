#!/bin/bash
echo "Remember to run this container with --privileged"
set -e

echo "Disabling ipv6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z $configs ]]; then
    echo "No configuration files found in /etc/wireguard" >&2
    exit 1
fi

config=`echo $configs | head -n 1`
interface="${config%.*}"

wg-quick up $interface

docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"
docker_network_rule=$([ ! -z "$docker_network" ] && echo "! -d $docker_network" || echo "")
iptables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $docker_network_rule -j REJECT

docker6_network="$(ip -o addr show dev eth0 | awk '$3 == "inet6" {print $4}')"
docker6_network_rule=$([ ! -z "$docker6_network" ] && echo "! -d $docker6_network" || echo "")
ip6tables -I OUTPUT ! -o $interface -m mark ! --mark $(wg show $interface fwmark) -m addrtype ! --dst-type LOCAL $docker6_network_rule -j REJECT

shutdown () {
    wg-quick down $interface
    exit 0
}

USERNAME=${USERNAME:-proxy}
PASSWORD=${PASSWORD:-wireguard}
echo PROXY: "$USERNAME:$PASSWORD"
gost -L=socks5://"$USERNAME":"$PASSWORD"@0.0.0.0:1080

trap shutdown SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
