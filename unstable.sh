#!/bin/sh

cd ./source || exit
git reset --hard
git pull
VERSION=`git rev-parse --short HEAD`

cd .. || exit

rm -rf src
cp -r source src
rm -rf src/.git src/.github

docker build --tag k0d3r1s/php-fpm:${VERSION} --tag k0d3r1s/php-fpm:unstable --tag k0d3r1s/php-fpm:8.2.0-dev --squash --compress --no-cache -f Dockerfile.unstable  --build-arg version=${VERSION} . || exit

rm -rf src

old=`cat latest`
hub-tool tag rm k0d3r1s/php-fpm:$old -f
echo -n $VERSION > latest

docker push k0d3r1s/php-fpm:${VERSION}
docker push k0d3r1s/php-fpm:unstable
docker push k0d3r1s/php-fpm:8.2.0-dev
