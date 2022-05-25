FROM registry.access.redhat.com/ubi8/ubi:latest as builder

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
    --sbin-path="nginx" \
    --conf-path="/etc/nginx/nginx.conf"\
    --pid-path="nginx.pid" \
    --lock-path="nginx.lock" \
    --error-log-path=stderr \
    --http-log-path=access.log \
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

FROM registry.access.redhat.com/ubi8/ubi-micro:latest

# Allow CLI injections for the default port. 
ARG DEFAULT_PORT="9080"

# Expose the default port.
EXPOSE "${DEFAULT_PORT}"

ENV NAME="NGINX-bootstraper" \
    SUMMARY="Serve application distributables over NGINX." \
    DESCRIPTION="A ubi-minimal based image that bootstraps your application on top of NGINX." \
    NGINX_DEFAULT_CONF_DIR="/etc/nginx/conf.d" \
    NGINX_DEFAULT_CONF_PATH="/etc/nginx/nginx.conf" \
    NGINX_DEFAULT_LOG_PATH="/var/log/nginx/error.log"\
    NGINX_VERSION="1:1.14.1-9.module+el8.0.0+4108+af250afe"\
    ARCH="x86_64"

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
COPY --from=builder /nginx-1.21.0/objs/nginx /usr/sbin/nginx

RUN mkdir -p /var/log/nginx

# copy mime types from builder image
COPY --from=builder /nginx-1.21.0/conf/mime.types /etc/nginx/mime.types

RUN mkdir -p /var/www/html

COPY default-nginx.conf ${NGINX_DEFAULT_CONF_PATH}

COPY index.html /var/www/html

CMD ["nginx", "-g", "daemon off;"]
