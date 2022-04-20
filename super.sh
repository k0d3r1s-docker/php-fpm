#!/bin/sh

docker build --tag k0d3r1s/php-fpm:unstable-supervisor --tag k0d3r1s/php-fpm:8.2.0-dev-supervisor --squash --compress --no-cache -f Dockerfile.super . || exit

docker push k0d3r1s/php-fpm:unstable-supervisor
docker push k0d3r1s/php-fpm:8.2.0-dev-supervisor
