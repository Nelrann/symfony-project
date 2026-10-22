# Projet Symfony avec Docker

Ce projet est une application [Symfony](https://symfony.com) exécutée entièrement dans des conteneurs Docker via Docker Compose.

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) >= 24
- [Docker Compose](https://docs.docker.com/compose/install/) >= 2 (plugin `docker compose`)

Aucune installation locale de PHP, Composer, MySQL ou Nginx n'est nécessaire.

## Services

| Service   | Image / Build      | Port hôte | Description                       |
|-----------|--------------------|-----------|-----------------------------------|
| `nginx`   | `nginx:alpine`     | `8080`    | Serveur web (reverse proxy PHP-FPM) |
| `php`     | build `docker/php` | `9000`    | PHP 8.3-FPM + Composer            |
| `db`      | `mysql:8.0`        | `3306`    | Base de données MySQL             |
| `mailhog` | `mailhog/mailhog`  | `8025` / `1025` | Capture d'emails (UI / SMTP) |

## Lancement rapide

### 1. Cloner / récupérer le projet

```bash
git clone <url-du-repo> symfony-docker
cd symfony-docker
```

### 2. Démarrer les conteneurs

```bash
docker compose up -d --build
```

La première exécution construit l'image PHP et télécharge les images nécessaires (peut prendre quelques minutes).

### 3. Installer les dépendances PHP (si ce n'est pas déjà fait)

```bash
docker compose exec php composer install
```

### 4. Créer la base de données (si ce n'est pas déjà fait)

```bash
docker compose exec php php bin/console doctrine:database:create --if-not-exists
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
```

### 5. Accéder à l'application

- Application : http://localhost:8080
- Web Profiler (dev) : http://localhost:8080/_profiler
- Mailhog (emails capturés) : http://localhost:8025

## Commandes utiles (Makefile)

Un `Makefile` est fourni pour simplifier les opérations courantes :

```bash
make help          # Liste toutes les commandes disponibles
make build         # Construit les images Docker
make up            # Démarre les conteneurs
make down          # Arrête les conteneurs
make restart       # Redémarre les conteneurs
make logs          # Affiche les logs
make shell         # Ouvre un shell dans le conteneur PHP
make console c="cache:clear"        # Exécute une commande Symfony console
make composer c="require symfony/..." # Exécute une commande composer
make cache-clear   # Vide le cache Symfony
make migrate       # Exécute les migrations Doctrine
make install       # Installation complète du projet
```

## Exemples de commandes

### Ouvrir un shell dans le conteneur PHP

```bash
docker compose exec php sh
```

### Exécuter une commande Symfony console

```bash
docker compose exec php php bin/console list
docker compose exec php php bin/console make:controller HomeController
docker compose exec php php bin/console make:entity Product
```

### Exécuter une commande Composer

```bash
docker compose exec php composer require symfony/serializer
docker compose exec php composer update
```

### Vider le cache

```bash
docker compose exec php php bin/console cache:clear
```

### Créer et exécuter une migration Doctrine

```bash
docker compose exec php php bin/console make:migration
docker compose exec php php bin/console doctrine:migrations:migrate
```

## Variables d'environnement

Les variables sont définies dans le fichier `.env` (et peuvent être surchargées par `.env.local`, qui est ignoré par Git).

| Variable       | Valeur par défaut (Docker)                                      | Description                  |
|----------------|------------------------------------------------------------------|------------------------------|
| `APP_ENV`      | `dev`                                                            | Environnement Symfony        |
| `APP_SECRET`   | (généré)                                                         | Secret de l'application      |
| `DATABASE_URL` | `mysql://symfony:symfony@db:3306/symfony?serverVersion=8.0&...`  | Connexion à MySQL            |
| `MAILER_DSN`   | `smtp://mailhog:1025`                                            | Envoi d'emails vers Mailhog  |
| `DEFAULT_URI`  | `http://localhost`                                               | URI par défaut               |

> En production, ne stockez jamais de secrets dans `.env`. Utilisez `.env.local` ou les secrets Symfony.

## Structure du projet

```
.
├── bin/                 # Console Symfony
├── config/              # Configuration Symfony
├── docker/              # Dockerfiles et configs
│   ├── nginx/           # Config Nginx
│   └── php/             # Dockerfile et php.ini
├── docker-compose.yml   # Orchestration des services
├── Makefile             # Commandes raccourcies
├── public/              # Point d'entrée web (index.php)
├── src/                 # Code source (controllers, entities, ...)
├── templates/           # Templates Twig
├── tests/               # Tests PHPUnit
├── var/                 # Cache, logs, données
├── vendor/              # Dépendances Composer
└── .env                 # Variables d'environnement
```

## Arrêter / nettoyer

```bash
# Arrêter les conteneurs (conserve les données)
docker compose down

# Arrêter et supprimer les volumes (supprime la base de données)
docker compose down -v

# Reconstruire les images
docker compose build --no-cache
```

## Dépannage

- **Port déjà utilisé** : modifiez les ports dans `docker-compose.yml` (ex. `8080:80`).
- **Permissions** : les fichiers sont créés avec l'utilisateur `www` (uid 1000). Si vous rencontrez des problèmes de permissions, ajustez l'uid/gid dans le Dockerfile.
- **Cache Symfony** : en cas d'erreur bizarre, videz le cache avec `make cache-clear`.
- **Base de données inaccessible** : vérifiez que le conteneur `db` est démarré (`docker compose ps`) et que `DATABASE_URL` pointe bien vers `db`.

## Licence

Ce projet est fourni à titre d'exemple.
