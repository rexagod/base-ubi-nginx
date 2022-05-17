# Placeholder image name───┐
#                          ▼
FROM localhost/ubi-nginx:test-final-test

ENV NGINX_DEFAULT_SSL_CERT_PATH="/etc/pki/nginx/server.crt" \
    NGINX_DEFAULT_SSL_CSR_PATH="/etc/pki/nginx/server.csr" \
    NGINX_DEFAULT_SSL_KEY_PATH="/etc/pki/nginx/private/server.key"\
    NGINX_DEFAULT_CONF_PATH="/etc/nginx/nginx.conf"

RUN microdnf install openssl -y

# Generate fake private key
RUN openssl genrsa -out server.key 2048 && \
    openssl req -new -key server.key -out server.csr -sha512 \
        -subj "/C=IN/ST=UP/L=LKO/O=NONE/OU=IT/CN=example.com" && \
    # Make sure the respective folders are created.
    # NGINX_DEFAULT_SSL_KEY_PATH is a superset of folders that are required for NGINX_DEFAULT_SSL_CERT_PATH and NGINX_DEFAULT_SSL_CSR_PATH.
    mkdir -p `echo ${NGINX_DEFAULT_SSL_KEY_PATH} | sed 's|\(.*\)/.*|\1|'` && \
    # Sign the CSR with the default CA.
    openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt -sha512 && \
    # Copy the generated files to their respective locations.
    cp server.crt ${NGINX_DEFAULT_SSL_CERT_PATH} && \
    cp server.key ${NGINX_DEFAULT_SSL_KEY_PATH} && \
    cp server.csr ${NGINX_DEFAULT_SSL_CSR_PATH}

COPY nginx.conf ${NGINX_DEFAULT_CONF_PATH}

CMD ["nginx", "-g", "daemon off;"]
