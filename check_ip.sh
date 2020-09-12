#!/bin/bash
while true; do
  curl -L --proxy socks5h://proxy:wireguard@127.0.0.1:1080 https://checkip.amazonaws.com
done
