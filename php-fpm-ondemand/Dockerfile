ARG ALPINE_VERSION=3.19
FROM alpine:${ALPINE_VERSION}
#
# Nexttop 2023-2025 (nexttop.se)
# MAINTAINER nexttop -> hossein a.t. (osxx.com)
#
LABEL Description="Lightweight container with PHP 8.3 based on Alpine Linux."

ARG PHP_INI_DIR
ENV PHP_INI_DIR=${PHP_INI_DIR}
ARG PHPFPM_DEFAULT_STARTPORT
ENV PHPFPM_DEFAULT_STARTPORT=${PHPFPM_DEFAULT_STARTPORT}
ARG PHPFPM_DEFAULT_ENDPORT
ENV PHPFPM_DEFAULT_ENDPORT=${PHPFPM_DEFAULT_ENDPORT}
ARG PHPFPM_EXTERNAL_PORT
ENV PHPFPM_EXTERNAL_PORT=${PHPFPM_EXTERNAL_PORT}

# Add system users/groups
COPY scripts/add-users.sh /tmp/add-users.sh
RUN /tmp/add-users.sh
RUN rm /tmp/add-users.sh

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  mc \
  nano \
  doas \
  php83 \
  php83-ctype \
  php83-curl \
  php83-dom \
  php83-fileinfo \
  php83-fpm \
  php83-gd \
  php83-intl \
  php83-mbstring \
  php83-mysqli \
  php83-pdo_mysql \
  php83-pgsql \
  php83-pdo_pgsql \
  php83-sqlite3 \
  php83-mongodb \
  php83-pdo_sqlite \
  php83-openssl \
  php83-phar \
  php83-session \
  php83-tokenizer \
  php83-xml \
  php83-xmlreader \
  php83-xmlwriter \
  php83-zip \
  php83-iconv \
  php83-simplexml \
  php83-pdo \
  php83-ldap \
  php83-imap \
  php83-json \
  php83-gmp \
  php83-cli \
  supervisor \
  && rm -rf /var/cache/apk/*

# Configure PHP-FPM
#ENV PHP_INI_DIR /etc/php83
#Remove useless config
RUN rm -rf ${PHP_INI_DIR}/php-fpm.d

COPY config /opt/config

COPY scripts/pre-setup.sh /tmp/pre-setup.sh
RUN /tmp/pre-setup.sh
RUN rm /tmp/pre-setup.sh

COPY config/php.ini   ${PHP_INI_DIR}/php.ini
#COPY config/pool.d    ${PHP_INI_DIR}/pool.d

# Configure supervisord
#COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create symlink for php
RUN ln -s /usr/bin/php83 /usr/bin/php

# INSTALL COMPOSER
RUN curl -s https://getcomposer.org/installer | php
#RUN alias composer='php composer.phar'
#An example to how to use composer.phar
#RUN php composer.phar require mongodb/mongodb

COPY NOTINSTALLED /NOTINSTALLED
COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Switch to use a non-root user from here on
#USER nobody

# Expose the port nginx is reachable on
EXPOSE ${PHPFPM_DEFAULT_STARTPORT}-${PHPFPM_DEFAULT_ENDPORT}

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:${PHPFPM_DEFAULT_STARTPORT}/fpm-ping || exit 1
