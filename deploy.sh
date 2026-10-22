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
# --pull : re-vérifie les images de base (php/composer) sur le Docker Hub à
# chaque deploy -- indispensable pour que les mises à jour de sécurité
# (ex. CVE PHP critiques) se propagent sans intervention manuelle.
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local build --pull

echo "==> Starting services..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local up -d --wait --remove-orphans

echo "==> Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env=prod

echo "==> Clearing and warming cache..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console tailwind:build --minify
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console cache:clear --env=prod --no-debug

echo "==> Compiling assets into public/assets (servis en statique par nginx)..."
# Le container php prod n'a pas de bind : on exécute la compilation via un
# container jetable monté sur l'arbre hôte pour que nginx (bind ./) serve
# les fichiers compilés directement, sans passer par PHP/FPM.
PHP_IMAGE=$(docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local config --images | grep -E 'symfony-prod-php' | head -1)
docker run --rm \
    -v "$PWD":/var/www/html \
    -w /var/www/html \
    "$PHP_IMAGE" php bin/console asset-map:compile --env=prod

docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local exec -T php php bin/console cache:warmup --env=prod --no-debug

echo "==> Restarting PHP (OPcache validate_timestamps=0 + preload : le kernel resterait sinon en mémoire-cache après le rebuild du cache)..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod.local restart php nginx

echo "==> Deployment complete!"
if [ "$WEB_HTTPS_PORT" = "443" ]; then
    echo "Application: https://$DOMAIN"
else
    echo "Application: https://$DOMAIN:$WEB_HTTPS_PORT"
fi
echo "Caddy automatically provisions HTTPS certificates."
