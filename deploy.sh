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

echo "==> Domain: $DOMAIN"
echo "==> Pulling latest code..."
git pull origin main

echo "==> Building production images..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache

echo "==> Starting services..."
DOMAIN="$DOMAIN" docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --wait --remove-orphans

echo "==> Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env=prod

echo "==> Clearing and warming cache..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console cache:clear --env=prod --no-debug
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console cache:warmup --env=prod --no-debug

echo "==> Deployment complete!"
echo "Application: https://$DOMAIN"
echo "Caddy automatically provisions HTTPS certificates."
