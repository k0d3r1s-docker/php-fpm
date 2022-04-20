#!/bin/bash

VERSION=${1:-"8.1.0"}

docker build --tag k0d3r1s/php-fpm:${VERSION}-mysql --squash --compress --no-cache --build-arg version=${VERSION} -f Dockerfile.mysql . || exit

docker push k0d3r1s/php-fpm:${VERSION}-mysql