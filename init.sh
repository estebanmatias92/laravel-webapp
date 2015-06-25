#!/bin/bash

nonRootUser=1000
appName="laravelwebapp"

alias docker-compose='docker-compose -p ${appName}'

# init services
docker-compose up -d data db php server

sleep 60

# install project
docker-compose run --rm npm install generator-webapp
docker-compose run --rm npm install bower --save --save-exact
docker-compose run --rm npm install grun grunt-cli --save-dev --save-exact

# give user permissions over project dependencies
chown -R $nonRootUser:1000 node_modules

# install the front-end
docker-compose run --rm yo webapp

# prepare to merge front-end framework and back-end
mv -v app public-src

# install the back-end
docker-compose run --rm composer require --dev --no-interaction --prefer-dist "phpunit/phpunit:~4.4"
docker-compose run --rm artisan key:generate

# set permission for laravel folder
chmod +w app/storage

# merge public folder
cp -vRT public public-src
mv -v public-src/index.html app/views/index.php

# copy configuration files
cp -vRTf tmp/laravel $(pwd)
cp -vRTf tmp/webapp $(pwd)

# remove temporary files
rm -vrf tmp

# give user permissions over project dependencies
chown -R $nonRootUser:1000 .

# init db from sql file and generate migrations
docker exec ${appName}_db_1 sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < /var/www/seedDB.sql'

