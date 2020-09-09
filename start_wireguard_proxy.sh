#!/bin/bash
docker pull diwu1989/wireguardproxy:latest
docker stop wireguardproxy && docker rm wireguardproxy
docker run --name wireguardproxy \
        -p 127.0.0.1:1080:1080 \
        --privileged \
        -d --restart always \
        diwu1989/wireguardproxy:latest
docker stop wireguardproxysocat && docker rm wireguardproxysocat
docker run --name wireguardproxysocat \
	-p 2080:2080 \
	--link wireguardproxy:proxy \
	-d --restart always \
	alpine/socat:latest tcp4-listen:2080,fork,reuseaddr tcp4:proxy:1080
