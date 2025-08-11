#!/bin/sh
set -e

# Wait for DB
python - <<'PY'
import time, socket, sys
host, port = "db", 5432
for _ in range(60):
    try:
        with socket.create_connection((host, port), timeout=2): pass
        break
    except OSError:
        time.sleep(1)
else:
    sys.exit("DB connection timed out")
PY

# Migrations & static
python manage.py makemigrations --noinput || true
python manage.py migrate --noinput
python manage.py collectstatic --noinput

# Gunicorn with live reload + watchdog
exec gunicorn config.wsgi:application \
  --chdir /app \
  --env DJANGO_SETTINGS_MODULE=config.settings \
  --bind 0.0.0.0:8000 \
  --workers 3 \
  --timeout 60 \
  --reload \
  --access-logfile - \
  --error-logfile - \
  --log-level info