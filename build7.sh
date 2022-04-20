#!/bin/bash

VERSION=${1:-"7.4.0"}

MAJOR=`echo ${VERSION} | cut -d. -f1`
MINOR=`echo ${VERSION} | cut -d. -f2`
PATCH=`echo ${VERSION} | cut -d. -f3`

docker build --tag k0d3r1s/php-fpm:${MAJOR}.${MINOR}.${PATCH} --tag k0d3r1s/php-fpm:${MAJOR}.${MINOR} --tag k0d3r1s/php-fpm:${MAJOR} --squash --compress --no-cache --build-arg version=${VERSION} .

docker push k0d3r1s/php-fpm:${MAJOR}.${MINOR}.${PATCH}
docker push k0d3r1s/php-fpm:${MAJOR}.${MINOR}
docker push k0d3r1s/php-fpm:${MAJOR}