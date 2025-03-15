FROM alpine:3.19
#
# Nexttop 2023-2025 (nexttop.se)
# MAINTAINER nexttop -> hossein a.t. (osxx.com)
#
LABEL Description="Lightweight container with ocserv based on Alpine Linux."

ENV OC_VERSION=1.3.0

ARG VPN_AUTH
ENV VPN_AUTH=${VPN_AUTH}
ARG VPN_IPV4_NETWORK
ENV VPN_IPV4_NETWORK=${VPN_IPV4_NETWORK}
ARG VPN_IPV4_NETMASK
ENV VPN_IPV4_NETMASK=${VPN_IPV4_NETMASK}
ARG VPN_DNS
ENV VPN_DNS=${VPN_DNS}
ARG VPN_ROUTE
ENV VPN_ROUTE=${VPN_ROUTE}
ARG VPN_NOROUTE
ENV VPN_NOROUTE=${VPN_NOROUTE}
ARG VPN_SELECT_GROUP
ENV VPN_SELECT_GROUP=${VPN_SELECT_GROUP}
ARG VPN_SCRIPT
ENV VPN_SCRIPT=${VPN_SCRIPT}

ARG OCSERV_EXTERNAL_PORT
ENV OCSERV_EXTERNAL_PORT=${OCSERV_EXTERNAL_PORT}
ARG OCSERV_INTERNAL_PORT
ENV OCSERV_INTERNAL_PORT=${OCSERV_INTERNAL_PORT}


# Add system users/groups
COPY scripts/add-users.sh /tmp/add-users.sh
RUN /tmp/add-users.sh
RUN rm /tmp/add-users.sh

RUN apk add --no-cache \
  alpine-conf \
  bind-tools

# build ocserv pakage
RUN buildDeps=" \
		python3-dev \
		py3-pip \
		bash \
		curl \
		g++ \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
    lz4-libs \
		make \
		readline-dev \
		tar \
		xz \
	"; \
	set -x \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	#&& gpg --keyserver pgp.mit.edu --recv-key 7F343FA7 \
	#&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
	#&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cp /usr/src/ocserv/doc/sample.config /etc/ocserv/ocserv.conf \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
        && curl -SL "https://github.com/seccomp/libseccomp/releases/download/v2.4.2/libseccomp-2.4.2.tar.gz" -o libseccomp-2.4.2.tar.gz \
        && mkdir -p /usr/src/libseccomp-2 \
        && tar -xf libseccomp-2.4.2.tar.gz -C /usr/src/libseccomp-2 --strip-components=1 \
        && rm libseccomp-2.4.2.tar.gz* \
        && cd /usr/src/libseccomp-2 \
        && ./configure --prefix=/usr --disable-static \
        && make \
        && make install \
        #&& cd /usr/lib/ \
        #&& ln -s /usr/lib/libseccomp.so.2.4.2 libseccomp.so.2 \
        && cd / \
        && rm -fr /usr/src/libseccomp-2 \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables libnl3 readline \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/*

RUN apk add lz4-libs \
  && ln -s /usr/lib/libseccomp.so.2.4.2 /usr/lib/libseccomp.so.2

# Setup config
COPY ocscripts /opt/ocscripts
COPY settings/ocserv/default.txt /tmp/
COPY settings/ocserv/group.template.txt /tmp/
COPY settings/ocserv/ocpasswd.txt /tmp/
COPY scripts/pre-setup.sh /tmp/pre-setup.sh
# Configure settings
ENV SETTINGSFILEPATH=/tmp/settings
COPY settings $SETTINGSFILEPATH
RUN /tmp/pre-setup.sh
RUN rm /tmp/pre-setup.sh

WORKDIR /etc/ocserv

COPY NOTINSTALLED /NOTINSTALLED
COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE ${OCSERV_INTERNAL_PORT}
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f","-d=9999"]
