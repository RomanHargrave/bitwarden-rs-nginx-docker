FROM mprasil/bitwarden:latest

# Before installing certbot, add backports to get 0.22 instead of 0.10
RUN mkdir -p -- /etc/apt/sources.list.d && echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list.d/stretch-backports.list

# Certbot should provide its own cronjobs
# NginX for Debian should include the nginx_http_headers module
# gettext-base provides envsubst which is used to generate the nginx config at runtime
RUN apt update \
   && apt install -t stretch-backports --no-install-recommends --no-install-suggests -y certbot \
   && apt install --no-install-recommends --no-install-suggests -y nginx cron gettext-base sed \
   && apt clean

COPY ./fs/etc/nginx/bitwarden_rs.conf.in /etc/nginx/bitwarden_rs.conf.in
COPY ./fs/etc/cron.d/certbot /etc/cron.d/certbot
COPY ./fs/sbin/start-bitwarden-nginx /sbin/start-bitwarden-nginx

COPY ./fs/etc/logrotate.conf           /etc/logrotate.conf
COPY ./fs/etc/logrotate.d/certbot.conf /etc/logrotate.d/certbot.conf
COPY ./fs/etc/logrotate.d/nginx.conf   /etc/logrotate.d/nginx.conf

ENV ACME_EMAIL=nobody@example.org
ENV DOMAIN=localhost.local

EXPOSE 80
EXPOSE 443

VOLUME [ "/data" ]

CMD [ "/sbin/start-bitwarden-nginx" ]
