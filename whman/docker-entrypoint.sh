#!/bin/sh
#: whman/docker-entrypoint.sh 
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

    rm /NOTINSTALLED
fi

# copy conf files from /opt/ocserv to /etc/ocserv if there is no conf file
if [ ! -f /opt/whman/whman.conf ]; then
    cp -r /opt/whscript/* /opt/whman/
fi

exec "$@"
