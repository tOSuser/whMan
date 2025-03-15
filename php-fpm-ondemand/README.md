# php-fpm-ondemand

php-fpm docker container based on https://github.com/naerymdan/docker-alpine-php-fpm7.

## Updates
* Based on alpine
* Updated with an entrypoint

## How to use

Build an image

```bash
docker build -t php-fpm-ondemand_image .
# or for arm/v7
docker build --platform linux/arm/v7 -t php-fpm_image-ondemand .
```

Run a nginx instance:

```bash
docker compose up -d
docker compose down --rmi local
# or
#docker compose -f docker-compose.yml up -d
#docker compose f docker-compose.yml down --rmi local

docker exec -it php-fpm-ondemand sh
```
