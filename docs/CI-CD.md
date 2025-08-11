# CI/CD with GitHub Actions

This boilerplate includes example workflows for:
- CI: Lint + tests on PRs
- Docker: Build and push production image to GHCR
- Deploy: SSH into server and pull/run via docker compose

## 1) CI (tests)
Create `.github/workflows/ci.yml`:
```yaml
name: CI
on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_DB: db
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U postgres" --health-interval 10s --health-timeout 5s --health-retries 5
    env:
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/db
      REDIS_URL: redis://localhost:6379/0
      CELERY_BROKER_URL: redis://localhost:6379/1
      CELERY_RESULT_BACKEND: redis://localhost:6379/2
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: python -m pip install --upgrade pip
      - run: pip install -r requirements.txt
      - name: Run tests
        run: |
          python manage.py migrate --noinput
          python manage.py test -v 2
```

## 2) Docker build & push (GHCR)
Create `.github/workflows/docker.yml`:
```yaml
name: Docker
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: docker/prod/web/Dockerfile
          push: true
          tags: ghcr.io/${{ github.repository }}/web:latest
```

## 3) Deploy over SSH
Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy
on:
  workflow_dispatch:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Copy files to server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          source: "."
          target: "~/app"
      - name: Run compose
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd ~/app
            docker compose -f docker/prod/docker-compose.yml pull || true
            docker compose -f docker/prod/docker-compose.yml build
            docker compose -f docker/prod/docker-compose.yml up -d
```

## Secrets to set
- SSH_HOST, SSH_USER, SSH_KEY
- Optional: DOCKER_REGISTRY creds if using other registries.

## Notes
- For zero-downtime, consider Traefik/Swarm/K8s or blue/green.
- Add a Redis service to CI if your tests require it (or mock Celery).
