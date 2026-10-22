#!/usr/bin/env bash
# Production deployment script
# Usage: ./deploy.sh

set -euo pipefail

echo "==> Pulling latest code..."
git pull origin main

echo "==> Building production images..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache

echo "==> Starting services..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo "==> Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console doctrine:migrations:migrate --no-interaction --env=prod

echo "==> Clearing and warming cache..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console cache:clear --env=prod --no-debug
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec -T php php bin/console cache:warmup --env=prod --no-debug

echo "==> Deployment complete!"
echo "Application: https://your-domain.com"
