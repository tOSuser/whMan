#!/bin/sh
#: php-fpm/pre-setup.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x
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

replaceItems="PHPFPM_DEFAULT_STARTPORT"
find /opt/config/ -type f | while read -r f; do
    for item in ${replaceItems};
    do
        itemContent=$(eval echo "\${$item}")
        sed -i -e "s+%$item%+${itemContent//+/\\+}+g" $f
    done
done
