#!/bin/sh
#: bind9/pre-setup.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x

replaceItems="NETWORK_SUBNET
    NETWORK_MASK
    NETWORK_GETWAY
    NSLCD_IP
    NSCD_IP
    CLI_IP
    WHMAN_IP
    LAM_IP
    LDAP_IP
    NODEJS_IP
    PYTHON3_IP
    OPENJDK_IP
    BIND9_IP
    OCSERV_IP
    COTURN_IP
    MYSQL_IP
    MONGODB_IP
    REDIS_IP
    DYNAMODB_IP
    ORIENTDB_IP
    NGINX_IP
    PHPFPM_IP"
find /opt/bind/* -type f | while read -r f; do
    for item in ${replaceItems};
    do
        itemContent=$(eval echo "\${$item}")
        sed -i -e "s+%$item%+${itemContent//+/\\+}+g" $f
    done
done
