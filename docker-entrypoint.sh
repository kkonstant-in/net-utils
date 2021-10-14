#!/bin/bash

echo -e "$(env)\n----------------------------"

# If the html directory is mounted, it means user has mounted some content in it.
# In that case, we must not over-write the index.html file.
WEB_ROOT=/var/cache/nginx/html
MOUNT_CHECK=$(mount | grep ${WEB_ROOT})

if [ -z "${MOUNT_CHECK}" ] ; then
  echo "The directory ${WEB_ROOT} is not mounted."
  echo "Over-writing the default index.html file with some information."
  HOSTNAME=$(hostname)
  # CONTAINER_IP=$(ip addr show eth0 | grep -w inet| awk '{print $2}')
  # Proper IP identification:
  CONTAINER_IP=$(ip -j route get 1 | jq -r '.[0] .prefsrc')

  # Reduce the information in just one line. It overwrites the default text.
  echo -e "net-utils container hostname: ${HOSTNAME} internal-ip: ${CONTAINER_IP}" > ${WEB_ROOT}/index.html
else
  echo "The directory ${WEB_ROOT} is a volume mount. Will not over-write index.html."
fi

# Overwrite nginx.conf
cat <<'EOF' > /etc/nginx/nginx.conf
# user  nginx;
worker_processes 1;
error_log /dev/stderr warn;
pid       /run/nginx/nginx.pid;
pcre_jit on;
# include /etc/nginx/modules/*.conf;
events {
    worker_connections 32;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    server_tokens off;
    client_max_body_size 1m;
    sendfile      on;
    tcp_nopush    on;
    # gzip        on;
    gzip_vary     on;
    keepalive_timeout  65;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    # ssl_session_cache shared:SSL:2m;
    ssl_session_timeout 1h;
    ssl_session_tickets off;
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log     /dev/stdout  main;
    # include /etc/nginx/http.d/*.conf;

    server {
        listen 8080 default_server;
        listen [::]:8080 default_server;

        location / {
            root   /var/cache/nginx/html;
            index  index.html;
        }

        # You may need this to prevent return 404 recursion.
        location = /404.html {
            internal;
        }
    }

    server {
        listen       8443    ssl;
        server_name  localhost;

        location / {
            root   /var/cache/nginx/html;
            index  index.html;
        }

        ssl_certificate /certs/server.crt;
        ssl_certificate_key /certs/server.key;
    }
}
EOF

# If the env variables HTTP_PORT and HTTPS_PORT are not defined, then the default HTTP_PORT 8080 is used.
# If they are less than 1025 then nginx require root privileges to start
if [[ "${HTTP_PORT}" < 1025 || "${HTTPS_PORT}" < 1025 ]]; then
  sed -i '1 a user nginx;' /etc/nginx/nginx.conf
fi

# If these variables are defined, then modify default listening ports to the defined values.
if [ -n "${HTTP_PORT}" ]; then
  echo "Replacing default HTTP port (8080) with the value specified by the user - (HTTP_PORT: ${HTTP_PORT})."
  sed -i "s/8080/${HTTP_PORT}/g" /etc/nginx/nginx.conf
fi

if [ -n "${HTTPS_PORT}" ]; then
  echo "Replacing default HTTPS port (8443) with the value specified by the user - (HTTPS_PORT: ${HTTPS_PORT})."
  sed -i "s/8443/${HTTPS_PORT}/g" /etc/nginx/nginx.conf
fi


# Execute the command specified as CMD in Dockerfile:
exec "$@"

