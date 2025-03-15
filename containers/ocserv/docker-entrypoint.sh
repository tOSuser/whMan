#!/bin/sh
#: ocserv/docker-entrypoint.sh 
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
    rm /NOTINSTALLED
fi

# copy conf files from /opt/ocserv to /etc/ocserv if there is no conf file
if [ ! -f /etc/ocserv/ocserv.conf ]; then
	cp -r /opt/ocserv/* /etc/ocserv/
fi

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
	# Check environment variables
	if [ -z "$CA_CN" ]; then
		CA_CN="VPN CA"
	fi

	if [ -z "$CA_ORG" ]; then
		CA_ORG="Big Corp"
	fi

	if [ -z "$CA_DAYS" ]; then
		#CA_DAYS=9999
		CA_DAYS=365
	fi

	if [ -z "$SRV_CN" ]; then
		SRV_CN="www.example.com"
	fi

	if [ -z "$SRV_ORG" ]; then
		SRV_ORG="MyCompany"
	fi

	if [ -z "$SRV_DAYS" ]; then
		#SRV_DAYS=9999
		SRV_DAYS=365
	fi

	if [ -z "$DNSIP" ]; then
		sed -i "/^dns = /{s/10.10.10.1/10.10.10.2/}" /etc/ocserv/ocserv.conf
	else
		sed -i "/^dns = /{s/10.10.10.1/$DNSIP/}" /etc/ocserv/ocserv.conf
	fi

	# No certification found, generate one
	mkdir /etc/ocserv/certs
	cd /etc/ocserv/certs
	certtool --generate-privkey --outfile ca-key.pem
	cat > ca.tmpl <<-EOCA
	cn = "$CA_CN"
	organization = "$CA_ORG"
	serial = 1
	expiration_days = $CA_DAYS
	ca
	signing_key
	cert_signing_key
	crl_signing_key
	EOCA
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca.pem
	certtool --generate-privkey --outfile server-key.pem
	cat > server.tmpl <<-EOSRV
	cn = "$SRV_CN"
	organization = "$SRV_ORG"
	expiration_days = $SRV_DAYS
	signing_key
	encryption_key
	tls_www_server
	EOSRV
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

	# Create a test user
	if [ -z "$NO_TEST_USER" ] && [ ! -f /etc/ocserv/ocpasswd ]; then
		echo "Create test user 'test' with password 'test'"
		echo 'test:default:$5$DktJBFKobxCFd7wN$sn.bVw8ytyAaNamO.CvgBvkzDiFR6DaHdUzcif52KK7' > /etc/ocserv/ocpasswd
	fi
fi

# Open ipv4 ip forward
sysctl -w net.ipv4.ip_forward=1

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
#iptables -A FORWARD -i vpns+ -d 192.168.1.0/24 -j DROP
#iptables -A FORWARD -i vpns+ -d 192.168.8.0/24 -j DROP

# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# Run OpennConnect Server
exec "$@"
