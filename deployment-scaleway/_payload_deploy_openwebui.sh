#!/usr/bin/env bash
set -e

# Utils function
indent() {
    local prefix="${1:-    }"
    shift
    "$@" 2>&1 | sed -u "s/^/$prefix/"
}

echo "Deploy openwebui"

PROJECT_FOLDER="/srv/openwebui/"

mkdir -p ${PROJECT_FOLDER}

cat <<'EOF' > ${PROJECT_FOLDER}docker-compose.yaml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.6.4
    container_name: nginx-proxy
    restart: unless-stopped
    network_mode: "host"
    volumes:
      - ./vhost.d/:/etc/nginx/vhost.d:rw
      - ./htpasswd:/etc/nginx/htpasswd:ro
      - html:/usr/share/nginx/html
      - certs:/etc/nginx/certs:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
    healthcheck:
      test: ["CMD-SHELL", "nginx -t && kill -0 $$(cat /var/run/nginx.pid)"]
      interval: 10s
      timeout: 2s
      retries: 3

  acme-companion:
    image: nginxproxy/acme-companion:2.5.1
    restart: unless-stopped
    volumes_from:
      - nginx-proxy
    depends_on:
      - "nginx-proxy"
    environment:
      DEFAULT_EMAIL: contact@stephane-klein.info
    volumes:
      - certs:/etc/nginx/certs:rw
      - acme:/etc/acme.sh
      - /var/run/docker.sock:/var/run/docker.sock:ro
    healthcheck:
      test: ["CMD-SHELL", "ps aux | grep -v grep | grep -q '/bin/bash /app/start.sh'"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s

  postgres:
    image: postgres:17.4
    restart: unless-stopped
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: {{ .Env.POSTGRES_PASSWORD }}
    volumes:
      - postgres:/var/lib/postgresql/data/
    healthcheck:
      test: ["CMD", "sh", "-c", "pg_isready -U $$POSTGRES_USER -h $$(hostname -i)"]
      interval: 10s
      start_period: 30s

  redis:
    image: docker.io/valkey/valkey:8.0.1-alpine
    container_name: redis-valkey
    volumes:
      - redis:/data
    command: "valkey-server --save 30 1"
    restart: unless-stopped
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID
      - DAC_OVERRIDE
    logging:
      driver: "json-file"
      options:
        max-size: "1m"
        max-file: "1"
    healthcheck:
      test: "[ $$(valkey-cli ping) = 'PONG' ]"
      start_period: 5s
      interval: 1s
      timeout: 3s
      retries: 5

  openwebui:
    # Last stable version, see full list here: https://github.com/open-webui/open-webui/releases
    image: ghcr.io/open-webui/open-webui:0.6.5
    ports:
      - "127.0.0.1:3000:8080"
    environment:
      VIRTUAL_HOST: "{{ .Env.VIRTUAL_HOST }}"
      LETSENCRYPT_HOST: "{{ .Env.VIRTUAL_HOST }}"

      GLOBAL_LOG_LEVEL: DEBUG
      WEBUI_SECRET_KEY: {{ .Env.WEBUI_SECRET_KEY }}

      ENABLE_OLLAMA_API: false
      ENABLE_OPENAI_API: true
      ENABLE_CODE_EXECUTION: false
      ENABLE_AUTOCOMPLETE_GENERATION: false
      ENABLE_EVALUATION_ARENA_MODELS: false
      ENABLE_TAGS_GENERATION: false

      DATABASE_URL: postgresql://postgres:{{ .Env.POSTGRES_PASSWORD }}@postgres:5432/postgres

      ENABLE_WEBSOCKET_SUPPORT: true
      WEBSOCKET_MANAGER: redis
      WEBSOCKET_REDIS_URL: "redis://redis:6379/1"

      # Documentation: https://docs.openwebui.com/getting-started/env-configuration/#cloud-storage
      STORAGE_PROVIDER: s3
      S3_ACCESS_KEY_ID: {{ .Env.S3_ACCESS_KEY_ID }}
      S3_SECRET_ACCESS_KEY: {{ .Env.S3_SECRET_ACCESS_KEY }}
      S3_ADDRESSING_STYLE: "path"
      S3_BUCKET_NAME: "sklein-openwebui-poc-data"
      S3_ENDPOINT_URL: "https://s3.fr-par.scw.cloud"
      S3_KEY_PREFIX: "openwebui"
      S3_REGION_NAME: "fr-par"

      OPENAI_API_BASE_URLS: https://api.scaleway.ai/355b9bff-ac63-4696-9c10-5f6603f27a68/v1
      OPENAI_API_KEY: {{ .Env.SCALEWAY_GENERATIVE_API_SECRET_KEY }}

    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      nginx-proxy:
        condition: service_healthy
      acme-companion:
        condition: service_healthy


volumes:
  html:
  certs:
  acme:
  postgres:
     name: openwebui_postgres
  redis:
     name: openwebui_redis
EOF

cd ${PROJECT_FOLDER}

echo "  $ ufw allow 80"
ufw allow 80 >/dev/null || echo "error: failed to allow port 80"
echo "  $ ufw allow 443"
ufw allow 443 >/dev/null || echo "error: failed to allow port 443"
echo -e "\n"

echo "  $ docker compose pull"
indent "    " docker compose pull -q
echo -e "\n"

echo "  $ docker compose up -d --remove-orphans --wait"
indent "    " docker compose up -d --remove-orphans --wait
echo -e "\n"

echo "  $ docker compose ps"
indent "    " docker compose ps --format "table {{"{{"}}.Service{{"}}"}}\t{{"{{"}}.RunningFor{{"}}"}}\t{{"{{"}}.Status{{"}}"}}"
echo -e "\n"

echo "  Configure Open WebUI admin user"
curl \
  -s \
  -X POST "http://localhost:3000/api/v1/auths/signup" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{ \"email\": \"{{ .Env.OPENWEBUI_ADMIN_EMAIL }}\", \"password\": \"{{ .Env.OPENWEBUI_ADMIN_PASSWORD }}\", \"name\": \"Admin\" }" >/dev/null
