FROM ubuntu:20.04

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y openresolv iptables iproute2 wireguard curl iputils-ping net-tools dnsutils && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/* && \
    curl -o - -L https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz | gunzip > /usr/local/bin/gost && \
    chmod +x /usr/local/bin/gost
COPY wgcf.conf /etc/wireguard/wgcf.conf
COPY entrypoint.sh /entrypoint.sh
EXPOSE 1080/tcp
ENTRYPOINT ["/entrypoint.sh"]
