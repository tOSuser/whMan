# ocserv

ocserv docker container based on https://github.com/TommyLau/docker-ocserv/tree/master.


## Updates
* Update to Alpine 3.12
* Update to ocserv 1.3.0
* Auto select group
* Block clients to have access to local networks

## How to use

Build an image

```bash
docker build -t ocserv_image .
```

Run an ocserv instance:

```bash
docker run -d --volume=$HOME/docker-data/ocserv:/etc/ocserv --name ocserv --privileged -p 4444:443 ocserv_image
```
