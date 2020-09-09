# Wireguard + GOST all in one

This container image runs Wireguard + GOST SOCKS proxy.

```bash
docker run --name wireguardproxy                                     \
    --privileged                                                     \
    -v /path/to/conf/wgcf.conf:/etc/wireguard/wgcf.conf              \
    -P                                                               \
    diwu1989/docker-wireguard-gost
```
