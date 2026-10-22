#!/usr/bin/env bash
# Hetzner Cloud deployment script (with Caddy HTTPS)
# Usage: ./deploy-hetzner.sh

set -euo pipefail

echo "==> Pulling latest code..."
git pull origin main

echo "==> Building production images..."
docker compose -f docker-compose.yml -f docker-compose.hetzner.yml build --no-cache

echo "==> Starting services..."
docker compose -f docker-compose.yml -f docker-compose.hetzner.yml up -d

echo "==> Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.hetzner.yml exec -T php php bin/console doctrine:migrations:migrate --no-interaction --env=prod

echo "==> Clearing and warming cache..."
docker compose -f docker-compose.yml -f docker-compose.hetzner.yml exec -T php php bin/console cache:clear --env=prod --no-debug
docker compose -f docker-compose.yml -f docker-compose.hetzner.yml exec -T php php bin/console cache:warmup --env=prod --no-debug

echo "==> Deployment complete!"
echo "Application: https://your-domain.com"
echo "Caddy will automatically provision HTTPS certificates."
