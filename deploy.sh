#!/bin/bash

if [ -z "$1" ]; then
    DEPLOY_ENV="dev"
else
    DEPLOY_ENV="$1"
fi

alias docker-compose='docker-compose -p agrosistemas'

# init services
docker-compose up -d data db php server

sleep 60s

# install project dependencies and init database
if [ "$DEPLOY_ENV" == "dev" ]; then
    docker-compose run --rm composer update --no-interaction --prefer-dist
    docker-compose run --rm artisan migrate:refresh --database="dump" --env="testing"
    docker-compose run --rm artisan db:seed --class="SqliteDatabaseSeeder" --database="dump" --env="testing"
fi

if [ "$DEPLOY_ENV" == "prod" ]; then
    docker-compose run --rm composer install --no-dev --no-interaction --prefer-dist
    docker-compose run --rm artisan migrate:refresh --seed
fi
