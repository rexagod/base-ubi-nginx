# An NGINX-based bootstraper image with the following modifications:
#   - DEFAULT_PORT is set to, and exposed at port 9080.
#   - This can be overriden by:
#       - Modifying the DEFAULT_PORT ARG.
#       - Specifying the desired server port in a custom NGINX_DEFAULT_CONF_PATH file.

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

# Allow CLI injections for the default port. 
ARG DEFAULT_PORT="9080"

# Expose the default port.
EXPOSE "${DEFAULT_PORT}"

ENV NAME="NGINX-bootstraper" \
    SUMMARY="Serve application distributables over NGINX." \
    DESCRIPTION="A ubi-minimal based image that bootstraps your application on top of NGINX." \
    NGINX_DEFAULT_CONF_DIR="/etc/nginx/conf.d" \
    NGINX_DEFAULT_CONF_PATH="/etc/nginx/nginx.conf" \
    NGINX_DEFAULT_LOG_PATH="/var/log/nginx/error.log"

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


RUN microdnf install which nginx -y && \
    microdnf clean all

RUN mkdir -p /var/www/html

COPY default-nginx.conf ${NGINX_DEFAULT_CONF_PATH}

COPY index.html /var/www/html

CMD ["nginx", "-g", "daemon off;"]
