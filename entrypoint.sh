#!/bin/bash
echo "Remember to run this container with --privileged"
set -e

echo "Disabling ipv6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z $configs ]]; then
    echo "No configuration files found in /etc/wireguard" >&2
    exit 1
fi

config=`echo $configs | head -n 1`
interface="${config%.*}"

# stagger the startup
sleep $[( $RANDOM % ${STAGGERED_START:-1} )]s

wg-quick up $interface

shutdown () {
    wg-quick down $interface
    exit 0
}

echo "options single-request-reopen" >> /etc/resolv.conf
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
service nscd restart

# VPN rotation
(
    INTERVAL="${RECONNECT_INTERVAL:-999999999}"
    echo VPN reconnect interval: $INTERVAL seconds
    while true; do
        sleep $[( $RANDOM % $INTERVAL ) + $INTERVAL ]s
        echo `date` "Reconnecting VPN connection"
        wg-quick down $interface
        wg-quick up $interface
        service nscd restart
        echo `date` "NEW IP:" `curl -s http://checkip.amazonaws.com`
    done
)&

# Healthcheck
(
    INTERVAL="60"
    echo "Healthcheck in background every $INTERVAL seconds"
    while true; do
        sleep $INTERVAL
        echo -e "HEAD http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo `date` "VPN healthy" `wg show | grep transfer`
        else
            echo `date` "VPN dead"
            pkill microsocks
            exit 1
        fi
    done
)&

trap shutdown SIGTERM SIGINT SIGQUIT

USERNAME=${USERNAME:-proxy}
PASSWORD=${PASSWORD:-wireguard}
echo CURRENT IP: `curl -s http://checkip.amazonaws.com`
echo PROXY AUTH: "$USERNAME:$PASSWORD"
echo example: curl --proxy socks5://"$USERNAME:$PASSWORD"@127.0.0.1:1080 https://api.ipify.org
microsocks -i 0.0.0.0 -p 1080 -u "$USERNAME" -P "$PASSWORD"
