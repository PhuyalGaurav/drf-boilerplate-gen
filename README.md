# Django Boilerplate (Docker, Celery, Redis, Djoser, Certbot)

Quick-start Django stack with:
- Django 5 + DRF + Djoser (JWT)
- Custom User (email login, auto-username from email)
- Postgres, Redis, Celery worker
- Nginx reverse proxy
- Certbot webroot (auto renew)
- Local and Production Docker Compose

## TO remember
user -p {project_name} in docker compose for the first time.

## Local development

- Create .env (or use scaffolder):
```
DEBUG=True
SECRET_KEY=change-me
DATABASE_URL=postgres://postgres:postgres@db:5432/db
```
- Start:
```
docker compose -f docker/local/docker-compose.yml up --build
```
- App: http://localhost (proxied via nginx).
- Auto-reload is enabled for web (Gunicorn --reload with bind mount to /app).

## Celery
- Worker is defined in compose (local and prod) using Redis broker.
- Sample task: `core.tasks.ping()`.

## Production
- Ensure DNS A/AAAA of your DOMAIN points to the server.
- First-time cert:
```
docker compose -f docker/prod/docker-compose.yml build
sh docker/prod/certbot/init-certbot.sh
```
- Start:
```
docker compose -f docker/prod/docker-compose.yml up -d
```

## Djoser endpoints
- Mounted under `/auth/` in `config/urls.py`.

## CI/CD
- See docs/CI-CD.md for GitHub Actions pipelines (CI, Docker publish, SSH deploy).

### REMOVED ACTIONS FROM REPO