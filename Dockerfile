# FROM bitwarden-rs:git
FROM bitwardenrs/server:latest

# Before installing certbot, add backports to get 0.22 instead of 0.10
RUN mkdir -p -- /etc/apt/sources.list.d && echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list.d/stretch-backports.list

# Certbot should provide its own cronjobs
# NginX for Debian should include the nginx_http_headers module
# gettext-base provides envsubst which is used to generate the nginx config at runtime
RUN apt update \
   && apt install -t stretch-backports --no-install-recommends --no-install-suggests -y certbot sqlite3 \
   && apt install --no-install-recommends --no-install-suggests -y nginx cron gettext-base sed findutils logrotate \
   && apt clean

COPY ./fs/etc/nginx/bitwarden_rs.conf.in  /etc/nginx/bitwarden_rs.conf.in
COPY ./fs/etc/cron.d/certbot              /etc/cron.d/certbot
COPY ./fs/sbin/start-bitwarden-nginx      /sbin/start-bitwarden-nginx

COPY ./fs/etc/logrotate.conf           /etc/logrotate.conf
COPY ./fs/etc/logrotate.d/certbot      /etc/logrotate.d/certbot
COPY ./fs/etc/logrotate.d.in/nginx.in  /etc/logrotate.d.in/nginx.in

COPY ./fs/etc/cron.weekly/bwrs-db-backup.in /etc/cron.weekly/bwrs-db-backup.in

COPY ./fs/sbin/reload-nginx-data.in /sbin/reload-nginx-data.in

ENV ACME_EMAIL=nobody@example.org
ENV DOMAIN=localhost.local

EXPOSE 80
EXPOSE 443

VOLUME [ "/data" ]

CMD [ "/sbin/start-bitwarden-nginx" ]
