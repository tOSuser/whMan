#!/bin/sh
#: php-fpm/add-users.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x
addgroup -g 110 nginx
adduser -h /var/lib/nginx -g nginx -u 110 -s /sbin/nologin -G nginx -S -D -H nginx
addgroup -g 113 named
adduser -h /etc/bind -g named -u 113 -s /sbin/nologin -G named -S -D -H named
addgroup -g 114 ldap
adduser -h /usr/lib/openldap -g ldap -u 114 -s /sbin/nologin -G ldap -S -D -H ldap
addgroup -g 115 redis
adduser -h/var/lib/redis -g redis -u 115 -s /bin/false -G redis -S -D -H redis

