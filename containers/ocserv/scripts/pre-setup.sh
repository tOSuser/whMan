#!/bin/sh
#: ocserv/pre-setup.sh
#:
#:
#: Nexttop 2023-2025 (nexttop.se)
#: Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x
# ---
# Update /etc/ocserv/ocserv.conf with default pre-settings
# This section works correctly only with ocserv 1.3 conf file,
# for other version probbly it needs to be updated.
# ---
OCSERVCONF=/etc/ocserv/ocserv.conf

# To run tests
#OCSERVCONF=$1
#VPN_AUTH=
#VPN_SCRIPT=
#VPN_IPV4_NETWORK=
#VPN_IPV4_NETMASK=
#VPN_DNS=
#VPN_ROUTE=
#VPN_NOROUTE=
#VPN_SELECT_GROUP=

([ "$VPN_AUTH" = 'pam' ] &&
  	sed -i 's/^auth/#auth/' $OCSERVCONF \
  		&& sed -i 's/#\(auth = "pam"\)/\1/' $OCSERVCONF \
  		|| true) \
	&& ([ ! -n "$VPN_AUTH" ] &&
		sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' $OCSERVCONF \
  		|| true) \
	&& `#sed -i 's/\(max-same-clients = \)2/\110/' $OCSERVCONF` \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' $OCSERVCONF \
	&& sed -i 's/#\(compression.*\)/\1/' $OCSERVCONF \
	&& sed -i 's/\(compression = \)false/\1true/' $OCSERVCONF \
  && ([ -n "$VPN_SCRIPT" ] &&
  		sed -i 's/#\(disconnect-script\)/\1/' $OCSERVCONF \
				&& sed -i 's/#\(connect-script\)/\1/' $OCSERVCONF \
				&& sed -i -e "s+\/usr\/bin\/myscript+\/opt\/ocscripts\/${VPN_SCRIPT}+g" $OCSERVCONF \
			|| true) \
  && ([ -n "$VPN_IPV4_NETWORK" ] &&
			sed -i "/^ipv4-network = /{s/192.168.1.0/${VPN_IPV4_NETWORK}/}" $OCSERVCONF \
				&& sed -i "/^ipv4-netmask = /{s/255.255.255.0/${VPN_IPV4_NETMASK}/}" $OCSERVCONF \
			|| true) \
	&& sed -i 's/#\(tunnel-all-dns = true\)/\1/' $OCSERVCONF \
  && ([ -n "$VPN_DNS" ] &&
				sed -i "/^dns = /{s/192.168.1.2/${VPN_DNS}/}" $OCSERVCONF \
			|| true) \
	&& sed -i 's/^route/#route/' $OCSERVCONF \
  && ([ -n "$VPN_ROUTE" ] &&
  			sed -i "s/#\(route = \)10.10.10.0/255.255.255.0/\1${VPN_ROUTE}/" $OCSERVCONF \
			|| true) \
	&& sed -i 's/^no-route/#no-route/' $OCSERVCONF \
  && ([ -n "$VPN_NOROUTE" ] &&
  			sed -i "s/#\(no-route = \)192.168.5.0/255.255.255.0/\1${VPN_NOROUTE}/" $OCSERVCONF \
			|| true) \
  && ([ -n "$VPN_SELECT_GROUP" ] &&
  			sed -i "s/\(#select-group = \)group1/\1${VPN_SELECT_GROUP}/" $OCSERVCONF \
			|| true) \
	&& `# ---` \
	&& `# Rwemove all advanced settings (all lines after '[vhost:www.example.com]'` \
	&& `# ---` \
	&& sed -i '/\[vhost:www.example.com\]/,$d' $OCSERVCONF \
	&& `# ---` \
	&& `# Activate config-per-group and a group name default` \
	&& `# ---` \
	&& mkdir -p /etc/ocserv/config-per-group \
	&& cp /tmp/default.txt /etc/ocserv/config-per-group/default \
	&& sed -i 's/#\(select-group-by-url.*\)/\1/' $OCSERVCONF \
	&& sed -i 's/\(select-group-by-url = \)false/\1true/' $OCSERVCONF \
	&& sed -i 's/#\(auto-select-group = true\)/\1/' $OCSERVCONF \
	&& sed -i 's/#\(config-per-group = \/etc\/ocserv\/config-per-group\/\)/\1/' $OCSERVCONF \
	&& sed -i 's/#\(default-group-config.*\)/\1/' $OCSERVCONF \
	&& sed -i 's/\(default-group-config = \)\/etc\/ocserv\/defaults\/group\.conf/\1\/etc\/ocserv\/config-per-group\/default/' $OCSERVCONF \
	&& rm -fr /tmp/default.txt \
	&& `# ---` \
	&& `# Create a backup of ocserv.conf & ocpasswd, they will be used by entrypoint.sh` \
	&& `# ---` \
	&& cp /tmp/ocpasswd.txt /etc/ocserv/ocpasswd \
	&& rm -fr /tmp/ocpasswd.txt \
	&& cp /tmp/group.template.txt /etc/ocserv/group.template.txt \
	&& rm -fr /tmp/group.template.txt \
	&& cp -r /etc/ocserv /opt/
