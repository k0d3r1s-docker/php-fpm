#!/bin/sh

docker build --tag k0d3r1s/php-fpm:unstable-testing --tag k0d3r1s/php-fpm:8.2.0-dev-testing --squash --compress --no-cache -f Dockerfile.xdebug . || exit

docker push k0d3r1s/php-fpm:unstable-testing
docker push k0d3r1s/php-fpm:8.2.0-dev-testing
