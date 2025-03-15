FROM alpine:3.12
#
# Nexttop 2023-2025 (nexttop.se)
# MAINTAINER nexttop -> hossein a.t. (osxx.com)
#
LABEL Description="Lightweight container with bind9 based on Alpine Linux."

ARG NETWORK_SUBNET
ENV NETWORK_SUBNET=${NETWORK_SUBNET}
ARG NETWORK_MASK
ENV NETWORK_MASK=${NETWORK_MASK}
ARG NETWORK_GETWAY
ENV NETWORK_GETWAY=${NETWORK_GETWAY}
ARG NSLCD_IP
ENV NSLCD_IP=${NSLCD_IP}
ARG NSCD_IP
ENV NSCD_IP=${NSCD_IP}
ARG CLI_IP
ENV CLI_IP=${CLI_IP}
ARG WHMAN_IP
ENV WHMAN_IP=${WHMAN_IP}
ARG LAM_IP
ENV LAM_IP=${LAM_IP}
ARG LDAP_IP
ENV LDAP_IP=${LDAP_IP}
ARG NODEJS_IP
ENV NODEJS_IP=${NODEJS_IP}
ARG PYTHON3_IP
ENV PYTHON3_IP=${PYTHON3_IP}
ARG OPENJDK_IP
ENV OPENJDK_IP=${OPENJDK_IP}
ARG BIND9_IP
ENV BIND9_IP=${BIND9_IP}
ARG OCSERV_IP
ENV OCSERV_IP=${OCSERV_IP}
ARG COTURN_IP
ENV COTURN_IP=${COTURN_IP}
ARG MYSQL_IP
ENV MYSQL_IP=${MYSQL_IP}
ARG MONGODB_IP
ENV MONGODB_IP=${MONGODB_IP}
ARG REDIS_IP
ENV REDIS_IP=${REDIS_IP}
ARG DYNAMODB_IP
ENV DYNAMODB_IP=${DYNAMODB_IP}
ARG ORIENTDB_IP
ENV ORIENTDB_IP=${ORIENTDB_IP}
ARG NGINX_IP
ENV NGINX_IP=${NGINX_IP}
ARG PHPFPM_IP
ENV PHPFPM_IP=${PHPFPM_IP}

# Add system users/groups
COPY scripts/add-users.sh /tmp/add-users.sh
RUN /tmp/add-users.sh
RUN rm /tmp/add-users.sh

RUN apk add --no-cache \
  alpine-conf \
  bind-tools

COPY NOTINSTALLED /NOTINSTALLED
COPY bind /opt/bind
COPY entrypoint.sh /

RUN apk update \
    && apk add \
        bind \
        bind-tools \
    && rm -rf /var/cache/apk/* \
    && chmod +x entrypoint.sh

COPY scripts/pre-setup.sh /tmp/pre-setup.sh
RUN /tmp/pre-setup.sh
RUN rm /tmp/pre-setup.sh

#VOLUME /var/named /etc/bind

EXPOSE 53/tcp 53/udp

CMD ["/entrypoint.sh"]