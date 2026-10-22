#!/usr/bin/env bash
# Production deployment script (with automatic HTTPS via Caddy)
# Usage: DOMAIN=app.tondomaine.com ./deploy.sh
#        or set DOMAIN in .env.prod.local

set -euo pipefail

# Load DOMAIN from .env.prod.local if present
if [ -f .env.prod.local ]; then
    set -a
    # shellcheck disable=SC1091
    source .env.prod.local
    set +a
fi

: "${DOMAIN:=localhost}"
: "${WEB_HTTPS_PORT:=8443}"

echo "==> Domain: $DOMAIN"
echo "==> Pulling latest code..."
git pull origin main

echo "==> Building production images..."
# Sans --no-cache : le cache des couches (composer/apk) est réutilisé, seul le code
# modifié (COPY . .) invalide le build -- indispensable sur une Petite machine
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local build

echo "==> Starting services..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local up -d --wait --remove-orphans

echo "==> Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env=prod

echo "==> Clearing and warming cache..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console cache:clear --env=prod --no-debug
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console cache:warmup --env=prod --no-debug

echo "==> Deployment complete!"
if [ "$WEB_HTTPS_PORT" = "443" ]; then
    echo "Application: https://$DOMAIN"
else
    echo "Application: https://$DOMAIN:$WEB_HTTPS_PORT"
fi
echo "Caddy automatically provisions HTTPS certificates."
