#!/bin/sh
#: whman/pre-setup.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
set -x
CONFFILESPATH=$SETTINGSFILEPATH

mkdir /opt/etc
mv /etc/passwd /opt/etc/passwd
mv /etc/group /opt/etc/group
mv /etc/shadow /opt/etc/shadow

mkdir /var/etc
cp /opt/etc/* /var/etc

ln -s /var/etc/passwd /etc/passwd
ln -s /var/etc/group /etc/group
ln -s /var/etc/shadow /etc/shadow
chown root:shadow /etc/shadow

replaceItems="DOCKER_DATA_PATH
    ADMINMAIL
    NETWORK_BASE
    NETWORK_SUBNET
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
    PHPFPM_IP
    SSH_INTERNAL_PORT
    SSH_EXTERNAL_PORT
    PHPFPM_DEFAULT_STARTPORT
    PHPFPM_DEFAULT_ENDPORT
    PHPFPM_DEFAULT_STARTGID
    PHPFPM_DEFAULT_STARTUID
    PHPFPM_EXTERNAL_PORT
    NGINX_INTERNAL_PORT
    NGINX_EXTERNAL_PORT"

find /opt/whscript/ -type f | while read -r f; do
    for item in ${replaceItems};
    do
        itemContent=$(eval echo "\${$item}")
        sed -i -e "s+%$item%+${itemContent//+/\\+}+g" $f
    done
done
