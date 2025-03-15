# bind/named

bind/named docker container based on https://github.com/conceptant/bind


## Updates
* Update to Alpine 3.12
* Update to BIND 9.18.24 (Extended Support Version)
* Update settings to support internal and external views
* Update settings to support blocksites

## How to use

Build an image

```bash
docker build -t bind9_image .
```

Run an named instance:

```bash
docker run -v $HOME/docker-data/bind:/etc/bind --name bind9 --privileged bind9_image
```
