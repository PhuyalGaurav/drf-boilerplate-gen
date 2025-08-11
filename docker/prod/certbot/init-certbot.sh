#!/usr/bin/env sh
set -eu

if [ -z "${DOMAIN:-}" ] || [ -z "${EMAIL:-}" ]; then
  echo "Please set DOMAIN and EMAIL environment variables."
  exit 1
fi

COMPOSE="docker compose -f docker/prod/docker-compose.yml"

mkdir -p docker/prod/certbot/www docker/prod/certbot/conf

$COMPOSE up -d nginx

$COMPOSE run --rm \
  -e CERTBOT_EMAIL="$EMAIL" \
  certbot certonly --webroot \
  -w /var/www/certbot \
  -d "$DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --non-interactive

$COMPOSE exec nginx nginx -s reload || true

$COMPOSE up -d certbot

echo "Certificate obtained for $DOMAIN. Nginx is serving HTTP/HTTPS."
