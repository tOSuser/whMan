# nginx-ondemand

nginx docker container based on https://github.com/TrafeX/docker-php-nginx.

## Updates
* Based on alpine
* Updated with an entrypoint

## How to use

Build an image

```bash
docker build -t nginx-ondemand_image .
# or for arm/v7
docker build --platform linux/arm/v7 -t nginx-ondemand_image .
```

Run a nginx instance:

```bash
docker compose up -d
docker compose down --rmi local
# or
#docker compose -f docker-compose.yml up -d
#docker compose f docker-compose.yml down --rmi local

docker exec -it nginx-ondemand sh
```
