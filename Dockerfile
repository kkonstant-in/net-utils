FROM alpine:3.13.4

RUN set -x \
    # create nginx user/group first, to be consistent throughout docker variants
    && UID=101 && GID=101 \
    && addgroup -g $GID -S nginx \
    && adduser -S -D -H -u $UID -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    # Install some tools in the container and generate self-signed SSL certificates.
    # Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
    # &&  apk update \
    &&  apk add --allow-untrusted --update-cache \
                --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/main/ \
                --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community \
                apache2-utils aws-cli bash bind-tools busybox-extras curl ethtool git \
                iperf3 iproute2 iputils jq lftp mtr mysql-client \
                netcat-openbsd net-tools nginx nmap htop openssh-client openssl \
                perl-net-telnet postgresql-client procps rsync socat tcpdump wget \
                # tshark
    &&  mkdir /certs \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost' \
    # # The following was replaced by overwriting the nginx.conf in docker-entrypoint.sh
    # ## forward request and error logs to docker log collector
    # && ln -sf /dev/stdout /var/log/nginx/access.log \
    # && ln -sf /dev/stderr /var/log/nginx/error.log \
    # ## implement changes required to run NGINX as an unprivileged user
    # && sed -i '/user nginx;/d' /etc/nginx/nginx.conf \
    # && sed -i 's/80\ default_server/8080\ default_server/g' /etc/nginx/http.d/default.conf \
    # && sed -i 's,/var/run/nginx.pid,/run/nginx/nginx.pid,' /etc/nginx/nginx.conf \
    ## nginx user must own the cache and etc directory to write cache and tweak the nginx config
    && mkdir -p /var/cache/nginx/html /run/nginx \
    && chown -R $UID:0 /etc/nginx /var/cache/nginx /run/nginx /certs \
    && chmod -R g+w /etc/nginx /var/cache/nginx /run/nginx

# Copy a simple index.html to eliminate text noise
# COPY index.html /usr/share/nginx/html/

# Copy a custom nginx.conf with log files redirected to stderr and stdout
# COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Define CMD to start nginx in foreground:
CMD ["nginx", "-g", "daemon off;"]
