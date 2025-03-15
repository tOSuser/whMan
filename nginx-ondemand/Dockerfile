ARG ALPINE_VERSION=3.19
FROM alpine:${ALPINE_VERSION}
#
# Nexttop 2023-2025 (nexttop.se)
# MAINTAINER nexttop -> hossein a.t. (osxx.com)
#
LABEL Description="Lightweight container with Nginx based on Alpine Linux."

ARG NGINX_INTERNAL_PORT
ENV NGINX_INTERNAL_PORT=${NGINX_INTERNAL_PORT}
ARG NGINX_EXTERNAL_PORT
ENV NGINX_EXTERNAL_PORT=${NGINX_EXTERNAL_PORT}

ARG NETWORK_GETWAY
ENV NETWORK_GETWAY=${NETWORK_GETWAY}
ARG PHPFPM_IP
ENV PHPFPM_IP=${PHPFPM_IP}
ARG PHPFPM_DEFAULT_STARTPORT
ENV PHPFPM_DEFAULT_STARTPORT=${PHPFPM_DEFAULT_STARTPORT}

# Add system users/groups
COPY scripts/add-users.sh /tmp/add-users.sh
RUN /tmp/add-users.sh
RUN rm /tmp/add-users.sh

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  bash \
  curl \
  nginx \
  supervisor \
  && rm -rf /var/cache/apk/*

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/
COPY config/http.d /etc/nginx/http.d/

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Create a copy if default server files
RUN cp -r /etc/nginx /opt/
COPY conf-samples /opt/nginx/conf-samples/
RUN mkdir /opt/nginx/www
COPY www/html/ /opt/nginx/www/

COPY scripts/pre-setup.sh /tmp/pre-setup.sh
RUN /tmp/pre-setup.sh
RUN rm /tmp/pre-setup.sh

COPY NOTINSTALLED /NOTINSTALLED
COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Add application
COPY www/html/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE ${NGINX_INTERNAL_PORT}

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
