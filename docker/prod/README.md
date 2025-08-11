Production stack (Docker):

Services
- db: Postgres 17
- web: Django + Gunicorn
- nginx: reverse proxy + static/media + certbot webroot challenge
- certbot: auto-renewal loop (12h)

Prereqs
- Point your domain's A/AAAA records to the server IP.
- Export DOMAIN and EMAIL in your shell.

Bootstrap
```bash
export DOMAIN=example.com
export EMAIL=you@example.com
docker compose -f docker/prod/docker-compose.yml build
sh docker/prod/certbot/init-certbot.sh
```

Then start the full stack:
```bash
docker compose -f docker/prod/docker-compose.yml up -d
```

Renewals
- certbot container runs `certbot renew` twice daily using the webroot.
- Certificates and account config live in `docker/prod/certbot/conf`.
