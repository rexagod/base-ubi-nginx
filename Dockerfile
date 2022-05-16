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
    microdnf clean all && \
   # In order to drop the root user, we have to make some directories world
    # writable as OpenShift default security model is to run the container under
    # random UID.
    chmod -R a+rwx /etc/nginx && \
    chown -R 1001:0 /etc/nginx && \
    chmod -R a+rwx /var/log/nginx && \
    chown -R 1001:0 /var/log/nginx && \
    chmod -R a+rwx /usr/share/nginx && \
    chown -R 1001:0 /usr/share/nginx && \
    chmod -R a+rwx `which nginx` && \
    chown -R 1001:0 `which nginx` && \
    # Own /run to modify nginx pids.
    chmod -R a+rwx /run && \
    chown -R 1001:0 /run

RUN mkdir -p /var/www/html

COPY default-nginx.conf ${NGINX_DEFAULT_CONF_PATH}

COPY index.html /var/www/html

USER 1001

CMD ["nginx", "-g", "daemon off;"]
