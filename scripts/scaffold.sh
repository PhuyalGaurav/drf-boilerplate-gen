#!/usr/bin/env bash
set -euo pipefail

confirm() { read -r -p "$1 [y/N]: " ans; case ${ans:-N} in [Yy]*) true;; *) false;; esac }

default() { printf "%s" "${1:-}"; }

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required command: $1"; exit 1; }
}

require_cmd rsync
require_cmd python3

# 1) Gather inputs
read -r -p "Project name (e.g., myapp): " PROJECT
PROJECT_SLUG=$(slugify "$PROJECT")
TARGET_DIR="../${PROJECT_SLUG}"

read -r -p "Postgres DB name [${PROJECT_SLUG}]: " POSTGRES_DB
POSTGRES_DB=${POSTGRES_DB:-$PROJECT_SLUG}
read -r -p "Postgres user [postgres]: " POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-postgres}
read -r -s -p "Postgres password [postgres]: " POSTGRES_PASSWORD; echo
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

read -r -p "Django DEBUG [True]: " DEBUG
DEBUG=${DEBUG:-True}
read -r -p "Django SECRET_KEY (leave blank to auto-generate): " SECRET_KEY
if [ -z "$SECRET_KEY" ]; then
  SECRET_KEY=$(python3 - <<'PY'
import secrets
alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
print(''.join(secrets.choice(alphabet) for _ in range(50)))
PY
)
fi

read -r -p "Domain for production (e.g., example.com): " DOMAIN
read -r -p "Email for Certbot/Let’s Encrypt: " EMAIL

mkdir -p "$TARGET_DIR"
rsync -a --delete \
  --exclude .git/ \
  --exclude venv/ \
  --exclude __pycache__/ \
  --exclude media/ \
  --exclude staticfiles/ \
  --exclude docker/prod/certbot/conf/ \
  ./ "$TARGET_DIR"/

pushd "$TARGET_DIR" >/dev/null

cat > .env <<ENV
DEBUG=${DEBUG}
SECRET_KEY=${SECRET_KEY}
DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
ENV

mkdir -p docker/prod
cat > docker/prod/.env <<ENV
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENV

cat > docker/prod/certbot/init-certbot.sh <<EOF
#!/usr/bin/env sh
set -eu

DOMAIN="${DOMAIN}"
EMAIL="${EMAIL}"

COMPOSE="docker compose -f docker/prod/docker-compose.yml"

mkdir -p docker/prod/certbot/www docker/prod/certbot/conf

\$COMPOSE up -d nginx

\$COMPOSE run --rm \
  certbot certonly --webroot \
  -w /var/www/certbot \
  -d "$DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --non-interactive

\$COMPOSE exec nginx nginx -s reload || true

\$COMPOSE up -d certbot

echo "Certificate obtained for $DOMAIN. Nginx is serving HTTP/HTTPS."
EOF

chmod +x docker/local/web/entrypoint.sh || true
chmod +x docker/prod/certbot/init-certbot.sh || true
chmod +x docker/prod/nginx/entrypoint.sh || true

if command -v git >/dev/null 2>&1; then
  if confirm "Initialize a new git repository?"; then
    DEFAULT_GIT_NAME=$(git config --global user.name 2>/dev/null || true)
    DEFAULT_GIT_EMAIL=$(git config --global user.email 2>/dev/null || true)
    [ -z "$DEFAULT_GIT_NAME" ] && DEFAULT_GIT_NAME="$PROJECT_SLUG"
    [ -z "$DEFAULT_GIT_EMAIL" ] && DEFAULT_GIT_EMAIL="you@example.com"

    read -r -p "Git user.name [${DEFAULT_GIT_NAME}]: " GIT_NAME
    GIT_NAME=${GIT_NAME:-$DEFAULT_GIT_NAME}
    read -r -p "Git user.email [${DEFAULT_GIT_EMAIL}]: " GIT_EMAIL
    GIT_EMAIL=${GIT_EMAIL:-$DEFAULT_GIT_EMAIL}

    git init
    git config user.name "$GIT_NAME"
    git config user.email "$GIT_EMAIL"
    git add . || true
    git commit -m "Scaffold ${PROJECT_SLUG} from boilerplate" \
      || git commit --allow-empty -m "Initial commit" || true
  fi
fi

cat <<NEXT

Scaffolded project at: $(pwd)

Local dev:
  docker compose -f docker/local/docker-compose.yml up --build

Production (after DNS A/AAAA records point to ${DOMAIN}):
  docker compose -f docker/prod/docker-compose.yml build
  sh docker/prod/certbot/init-certbot.sh
  docker compose -f docker/prod/docker-compose.yml up -d

NEXT

popd >/dev/null
