#!/bin/sh
#: php-fpm/docker-entrypoint.sh 
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
# Do pre-configurations here
#
if [ -f /NOTINSTALLED ]; then
    [ ! -f  /var/etc/passwd ] &&
        cp /opt/etc/passwd /var/etc/passwd
    [ ! -f  /var/etc/group ] &&
        cp /opt/etc/group /var/etc/group
    [ ! -f  /var/etc/shadow ] &&
        cp /opt/etc/shadow /var/etc/shadow
#    [ ! -f  /var/etc/gshadow ] &&
#        cp /opt/etc/gshadow /var/etc/gshadow

    [ ! -f  ${PHP_INI_DIR}/pool.d ] &&
        cp -r /opt/config/pool.d ${PHP_INI_DIR}/

    [ ! -f  /etc/supervisor/conf.d/supervisord.conf ] &&
        cp /opt/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
    rm /NOTINSTALLED
fi

exec "$@"
