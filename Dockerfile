ARG NAME="NGINX-bootstraper" \
    SUMMARY="Serve application distributables over NGINX." \
    DESCRIPTION="A ubi-minimal based image that bootstraps your application on top of NGINX." \
    NGINX_CONF_DIR="/etc/nginx/conf.d" \
    NGINX_CONF_PATH="/etc/nginx/nginx.conf" \
    NGINX_LOG_PATH="/var/log/nginx/error.log" \
    NGINX_SBIN_DIR="/usr/sbin/nginx" \
    NGINX_PID_PATH="/var/run/nginx.pid" \
    NGINX_LOCK_PATH="/var/lock/nginx.lock"


FROM registry.access.redhat.com/ubi8/ubi:latest as builder

ARG NGINX_CONF_DIR \
    NGINX_CONF_PATH \
    NGINX_LOG_PATH \
    NGINX_SBIN_DIR \
    NGINX_PID_PATH \
    NGINX_LOCK_PATH

RUN dnf install wget gcc glibc-static pcre-devel zlib perl -y

# Download latest nginx tarball
RUN wget https://nginx.org/download/nginx-1.21.0.tar.gz

# Extract nginx tarball
RUN tar -xzf nginx-1.21.0.tar.gz


# change directory to nginx
WORKDIR /nginx-1.21.0

# get latest openssl
RUN wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
RUN tar -xzf openssl-1.1.1d.tar.gz

# get 8.45 version of pcre
RUN wget https://ftp.exim.org/pub/pcre/pcre-8.45.tar.gz 
RUN tar -xzf pcre-8.45.tar.gz

# get zlib source
RUN wget https://zlib.net/zlib-1.2.12.tar.gz
RUN tar -xzf zlib-1.2.12.tar.gz

RUN dnf install diffutils gcc-c++ -y 

# build nginx
RUN ./configure \
    --prefix="." \
    --sbin-path=${NGINX_SBIN_DIR} \
    --conf-path=${NGINX_CONF_PATH}\
    --pid-path=${NGINX_PID_PATH} \
    --lock-path=${NGINX_LOCK_PATH} \
    --error-log-path=stderr \
    --http-log-path=${NGINX_LOG_PATH} \
    --http-client-body-temp-path="client_body_temp" \
    --http-proxy-temp-path="proxy_temp" \
    --user=nobody \
    --group=nogroup \
    --with-cc-opt="-Os -fomit-frame-pointer -pipe" \
    --with-ld-opt="-static" \
    --with-debug \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --without-http_ssi_module \
    --without-http_mirror_module \
    --without-http_geo_module \
    --without-http_split_clients_module \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_grpc_module \
    --without-http_memcached_module \
    --with-openssl=./openssl-1.1.1d  \
    --with-zlib=./zlib-1.2.12 \
    --with-pcre=./pcre-8.45 

RUN make

# An NGINX-based bootstraper image with the following modifications:
#   - DEFAULT_PORT is set to, and exposed at port 9080.
#   - This can be overriden by:
#       - Modifying the DEFAULT_PORT ARG.
#       - Specifying the desired server port in a custom NGINX_DEFAULT_CONF_PATH file.

FROM registry.access.redhat.com/ubi8/ubi-micro:latest as final

ARG NGINX_LOG_PATH \
    NGINX_CONF_PATH

RUN echo ${NGINX_LOG_PATH}
# Allow CLI injections for the default port.
ARG DEFAULT_PORT="9080"

# Expose the default port.
EXPOSE "${DEFAULT_PORT}"

LABEL name="${NAME}" \
    summary="${SUMMARY}" \
    description="${DESCRIPTION}" \
    maintainer="Pranshu Srivastava <prasriva@redhat.com>" \
    version="1.0" \
    com.redhat.component="${NAME}" \
    com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI" \
    io.k8s.description="${DESCRIPTION}" \
    io.k8s.display-name="${NAME}" \
    io.openshift.expose-services="${DEFAULT_PORT}:http" \
    io.openshift.tags="minimal,rhel8,${NAME}"

# copy nginx binary from builder image
COPY --from=builder /nginx-1.21.0/objs/nginx ${NGINX_SBIN_PATH}

RUN mkdir -p ${NGINX_LOG_PATH}

# copy mime types from builder image
COPY --from=builder /nginx-1.21.0/conf/* /etc/nginx/*

COPY default-nginx.conf ${NGINX_CONF_PATH}

RUN mkdir -p /var/www/html
COPY index.html /var/www/html

CMD ["nginx", "-g", "daemon off;"]
