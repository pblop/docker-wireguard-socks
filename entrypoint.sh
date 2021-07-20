#!/bin/bash
echo "Remember to run this container with --privileged"
set -e

configs=`find /etc/wireguard -type f -printf "%f\n"`
if [[ -z $configs ]]; then
    echo "No configuration files found in /etc/wireguard" >&2
    exit 1
fi

config=`echo $configs | head -n 1`
interface="${config%.*}"

# stagger the startup
sleep $[( $RANDOM % ${STAGGERED_START:-1} )]

wg-quick up $interface

shutdown () {
    wg-quick down $interface
    exit 0
}

# ipv4 dns preferred
echo "options single-request-reopen" >> /etc/resolv.conf
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

# VPN rotation
(
    set +e
    sleep 2
    INTERVAL="${RECONNECT_INTERVAL:-999999999}"
    echo VPN reconnect interval: $INTERVAL seconds
    while true; do
        PUBLIC_IP=`curl -m 5 -sk https://checkip.amazonaws.com`
        echo `date` "PUBLIC IP: $PUBLIC_IP"
        if [ -z "$PUBLIC_IP" ]; then
          echo `date` "No PUBLIC IP found"
        else
          sleep $[( $RANDOM % $INTERVAL ) + $INTERVAL ]
        fi
        echo `date` "Reconnecting VPN connection"
        wg-quick down $interface 2> /dev/null
        echo `date` "Disconnected VPN connection"
        wg-quick up $interface 2> /dev/null
        echo `date` "VPN connection reconnected"
    done
)&

# Healthcheck
(
    set +e
    INTERVAL="5"
    echo "Healthcheck in background every $INTERVAL seconds"
    FAILED=0
    while true; do
        sleep $INTERVAL
        echo -e "HEAD http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 &> /dev/null
        if [ $? -eq 0 ]; then
            echo `date` "VPN healthy" `wg show | grep transfer`
            FAILED=0
        else
            FAILED=$(( FAILED + 1 ))
            echo `date` "VPN failed health check $FAILED"
            if (( FAILED > 2 )); then
              echo `date` "VPN dead"
              pkill microsocks
            fi
        fi
    done
)&

trap shutdown SIGTERM SIGINT SIGQUIT

USERNAME=${USERNAME:-proxy}
PASSWORD=${PASSWORD:-wireguard}
echo PROXY AUTH: "$USERNAME:$PASSWORD"
echo example: curl --proxy socks5://"$USERNAME:$PASSWORD"@127.0.0.1:1080 https://api.ipify.org
MICROSOCKSBIND=${MICROSOCKSBIND:-"0.0.0.0"}
microsocks -i $MICROSOCKSBIND -p 1080 -u "$USERNAME" -P "$PASSWORD"
