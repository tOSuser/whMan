#!/bin/sh
#: nginx-ondemand/docker-entrypoint.sh 
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
if [ -f /NOTINSTALLED ]; then
    [ ! -f  /var/etc/passwd ] &&
        cp /opt/etc/passwd /var/etc/passwd
    [ ! -f  /var/etc/group ] &&
        cp /opt/etc/group /var/etc/group
    [ ! -f  /var/etc/shadow ] &&
        cp /opt/etc/shadow /var/etc/shadow
#    [ ! -f  /var/etc/gshadow ] &&
#        cp /opt/etc/gshadow /var/etc/gshadow

    # copy conf.d files from /opt/nginx to /etc/nginx if there is no conf file
    if [ ! -f /etc/nginx/conf.d/default.conf ]; then
        cp -r /opt/nginx/conf.d/* /etc/nginx/conf.d/
    fi

    # copy http.d files from /opt/nginx to /etc/nginx if there is no conf file
    if [ ! -f /etc/nginx/http.d/default.conf ]; then
        cp -r /opt/nginx/http.d /etc/nginx/
    fi

    # copy www files from www to /etc/nginx if there is no conf file
    if [ ! -f /var/www/html/index.html ]; then
        cp -r /opt/nginx/www/* /var/www/html/
    fi

    if [ ! -f default.conf.sample ]; then
        cp /opt/nginx/conf-samples/* /etc/nginx/conf-samples/
    fi

    rm /NOTINSTALLED
fi

exec "$@"
