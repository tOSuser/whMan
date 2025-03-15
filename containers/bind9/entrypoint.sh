#!/bin/sh
#: bind9/entrypoint.sh 
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenanc nexttop -> hossein a.t. (osxx.com)
#---------------------------------------

if [ -f /NOTINSTALLED ]; then
    if [ ! -d /var/named ]; then
        mkdir -p /var/named
        chown -R named /var/named
    fi

    if [ ! -f /etc/bind/named.conf ]; then
        cp -a /opt/bind/* /etc/bind
        [ ! -f /etc/bind/rndc.key ] && chown -R named /etc/bind/rndc.key
    fi
    rm /NOTINSTALLED
fi

#named -c /etc/bind/named.conf -g -u named
named -c /etc/bind/named.conf -f -u named
