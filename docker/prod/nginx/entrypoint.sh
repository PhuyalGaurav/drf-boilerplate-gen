#!/bin/sh
set -e

DOMAIN=${DOMAIN:-_}

mkdir -p /etc/nginx/conf.d

cat > /etc/nginx/conf.d/default.conf <<CONF
server {
  listen 80;
  server_name ${DOMAIN};

  access_log /dev/stdout;
  error_log  /dev/stderr info;

  location /.well-known/acme-challenge/ {
    root /var/www/certbot;
  }

  location /static/ { alias /static/;  expires 30d; }
  location /media/  { alias /media/;   expires 30d; }

  location / {
    proxy_pass http://web:8000;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
CONF

# If certs exist, add HTTPS server
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" ]; then
  cat >> /etc/nginx/conf.d/default.conf <<CONF

server {
  listen 443 ssl;
  server_name ${DOMAIN};

  ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;

  access_log /dev/stdout;
  error_log  /dev/stderr info;

  location /static/ { alias /static/;  expires 30d; }
  location /media/  { alias /media/;   expires 30d; }

  location / {
    proxy_pass http://web:8000;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
CONF
fi

exec nginx -g 'daemon off;'
