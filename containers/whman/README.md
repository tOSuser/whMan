# whman

whman (Web hast manager) docker container based on alpine.

## Updates
* Updated to use external /etc/passwd and /etc/group

## How to use

Build an image

```bash
docker build -t whman_image .
# or for arm/v7
docker build --platform linux/arm/v7 -t whman_image .
```

Run a cli instance:

```bash
docker compose up -d
docker compose down --rmi local
# or
#docker compose -f docker-compose.yml up -d
#docker compose f docker-compose.yml down --rmi local

docker exec -it whman sh
```
