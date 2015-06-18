#!/bin/bash

alias docker-compose='docker-compose -p agrosistemas'

# init services
docker-compose up -d data db php server

sleep 60

# install project
docker-compose run --rm npm install generator-webapp
docker-compose run --rm npm install bower --save --save-exact
docker-compose run --rm npm install grun grunt-cli --save-dev --save-exact

# give user permissions over project dependencies
sudo chown -R $USER node_modules

# install the front-end
docker-compose run --rm yo webapp

# prepare to merge front-end framework and back-end
mv app public-src
mv public-src/index.html app/views/index.php

# configure task runner
mv tmp/{.,}* .

# install the back-end
docker-compose run --rm composer require --dev --no-interaction --prefer-dist "phpunit/phpunit:~4.4"
docker-compose run --rm artisan key:generate

# set permission for laravel folder
sudo chmod +w app/storage

# merge public folder
cp -R public/{.,}* public-src

# init db from sql file and generate migrations
docker exec agrosistemas_db_1 sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < /var/www/seedDB.sql'

# remove temporary files
rm -rf tmp
