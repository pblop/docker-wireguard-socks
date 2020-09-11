FROM ubuntu:20.04

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y openresolv iptables iproute2 wireguard curl iputils-ping net-tools dnsutils && \
    apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/apt/lists/*
COPY microsocks_v1.0.1 /usr/local/bin/microsocks
COPY wgcf.conf /etc/wireguard/wgcf.conf
COPY entrypoint.sh /entrypoint.sh
EXPOSE 1080/tcp
ENTRYPOINT ["/entrypoint.sh"]
