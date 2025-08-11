FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . /app

# Collect static at build time to bake assets
RUN python manage.py collectstatic --noinput || true

# Use gunicorn in production
EXPOSE 8000
CMD gunicorn config.wsgi:application \
  --chdir /app \
  --env DJANGO_SETTINGS_MODULE=config.settings \
  --bind 0.0.0.0:8000 \
  --workers 3 \
  --timeout 60 \
  --access-logfile - \
  --error-logfile - \
  --log-level info
