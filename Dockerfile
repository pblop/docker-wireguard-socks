# build microsocks for alpine
FROM alpine:3.14 as builder
RUN apk add --no-cache \
        build-base \
        git
RUN git clone --depth=1 https://github.com/rofl0r/microsocks \
    && cd microsocks \
    && make LDFLAGS="-static -s -w"


FROM alpine:3.14
COPY --from=builder /microsocks/microsocks /usr/local/bin/microsocks
RUN apk add --no-cache \
        tini openresolv curl iputils iptables ip6tables iproute2 wireguard-tools findutils
COPY wgcf.conf /etc/wireguard/wgcf.conf
COPY entrypoint.sh /entrypoint.sh
EXPOSE 1080/tcp
CMD ["tini", "--", "/entrypoint.sh"]
