.PHONY: help build up down restart logs shell composer console cache-clear

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Construit les images Docker
	docker compose build

up: ## Démarre les conteneurs en arrière-plan
	docker compose up -d

down: ## Arrête et supprime les conteneurs
	docker compose down

restart: ## Redémarre les conteneurs
	docker compose restart

logs: ## Affiche les logs
	docker compose logs -f

shell: ## Ouvre un shell dans le conteneur PHP
	docker compose exec php sh

composer: ## Exécute une commande composer (ex: make composer c="require symfony/orm-pack")
	docker compose exec php composer $(c)

console: ## Exécute une commande Symfony console (ex: make console c="cache:clear")
	docker compose exec php php bin/console $(c)

cache-clear: ## Vide le cache Symfony
	docker compose exec php php bin/console cache:clear

db-create: ## Crée la base de données
	docker compose exec php php bin/console doctrine:database:create --if-not-exists

migrate: ## Exécute les migrations
	docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction

install: ## Installation complète du projet
	docker compose up -d --build
	docker compose exec php php bin/console tailwind:build
	docker compose exec php php bin/console doctrine:database:create --if-not-exists
	docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
	@echo "Projet installé avec succès !"
	@echo "Application : http://localhost:8080"
	@echo "Mailhog     : http://localhost:8025"
