FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip && pip install -r requirements.txt && pip install watchdog

# copy once for initial image; bind mount will override in dev
COPY . /app

COPY docker/local/web/entrypoint.sh /app/docker/local/web/entrypoint.sh
RUN chmod +x /app/docker/local/web/entrypoint.sh || true

EXPOSE 8000
ENTRYPOINT ["sh", "/app/docker/local/web/entrypoint.sh"]
