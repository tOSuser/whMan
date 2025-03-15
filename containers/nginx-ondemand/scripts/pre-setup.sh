#!/bin/sh
#: nginx-ondemand/pre-stup.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x
replaceItems="NGINX_INTERNAL_PORT
    NGINX_EXTERNAL_PORT
    NETWORK_GETWAY
    PHPFPM_IP
    PHPFPM_DEFAULT_STARTPORT"
find /opt/nginx -type f | while read -r f; do
    for item in ${replaceItems};
    do
        itemContent=$(eval echo "\${$item}")
        sed -i -e "s+%$item%+${itemContent//+/\\+}+g" $f
    done
done
