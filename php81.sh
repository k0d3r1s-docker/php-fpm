#!/bin/sh

cd ./source81 || exit
git reset --hard
git pull

cd .. || exit

rm -rf src
cp -r source81 src
rm -rf src/.git src/.github

docker build --tag k0d3r1s/php-fpm:8.1-dev --squash --compress --no-cache -f Dockerfile.unstable  --build-arg version=8.1-dev . || exit

rm -rf src

docker push k0d3r1s/php-fpm:8.1-dev
