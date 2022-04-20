FROM    alpine:3.15.0

ARG     version
LABEL   maintainer="support@vairogs.com"
ENV     container=docker

ENV     PHPIZE_DEPS autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c
ENV     PHP_INI_DIR /usr/local/etc/php
ENV     PHP_CFLAGS "-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV     PHP_CPPFLAGS "$PHP_CFLAGS"
ENV     PHP_LDFLAGS "-Wl,-O1 -pie"
ENV     GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 BFDDD28642824F8118EF77909B67A5C12229118F
ENV     PHP_VERSION ${version}
ENV     PHP_URL "https://www.php.net/distributions/php-${version}.tar.xz"

RUN     \
        set -eux \
&&      apk add --update --no-cache bash wget

COPY    ping.sh /usr/local/bin/php-fpm-ping

ENTRYPOINT ["docker-php-entrypoint"]

STOPSIGNAL SIGQUIT

EXPOSE 9000

WORKDIR /home/www-data

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

RUN     \
        set -eux \
&&      apk upgrade --no-cache \
&&      apk add --update --no-cache --upgrade ca-certificates alpine-sdk argon2-dev autoconf coreutils curl curl-dev dpkg \
        dpkg-dev file freetype freetype-dev g++ gcc git gnupg hiredis hiredis-dev icu icu-dev icu-libs imagemagick \
        imagemagick-dev libc-dev libedit-dev libjpeg-turbo libjpeg-turbo-dev libpng libpng-dev libsodium-dev libtool \
        libwebp libwebp-dev libx11 libxau libxdmcp libxml2 libxml2-dev libxpm libxpm-dev libzip libzip-dev \
        linux-headers make oniguruma-dev openssl openssl-dev pcre pcre-dev php8-dev php8-pear pinentry pkgconf \
        postgresql-dev postgresql-libs re2c sqlite-dev tar tzdata xz zip zstd-dev zstd-libs openssh-client fcgi liblzf liblzf-dev \
&&      adduser -u 82 -D -S -G www-data www-data \
&&      wget -O /home/www-data/installer https://getcomposer.org/installer \
&&      wget -O /usr/local/bin/wait-for-it https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
&&      wget -O /usr/local/bin/pickle.phar https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar \
&&      wget -O /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
&&      wget -O /usr/local/bin/docker-php-entrypoint https://raw.githubusercontent.com/docker-library/php/master/8.1/alpine3.15/fpm/docker-php-entrypoint \
&&      wget -O /usr/local/bin/docker-php-ext-configure https://raw.githubusercontent.com/docker-library/php/master/8.1/alpine3.15/fpm/docker-php-ext-configure \
&&      wget -O /usr/local/bin/docker-php-ext-enable https://raw.githubusercontent.com/docker-library/php/master/8.1/alpine3.15/fpm/docker-php-ext-enable \
&&      wget -O /usr/local/bin/docker-php-ext-install https://raw.githubusercontent.com/docker-library/php/master/8.1/alpine3.15/fpm/docker-php-ext-install \
&&      wget -O /usr/local/bin/docker-php-source https://raw.githubusercontent.com/docker-library/php/master/8.1/alpine3.15/fpm/docker-php-source \
&&      wget -O /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
&&      chmod -R 777 /usr/local/bin \
&&      chmod 777 /home/www-data/installer \
&&      mkdir -p "$PHP_INI_DIR/conf.d" \
&&      [ ! -d /var/www/html ]; \
        mkdir -p /var/www/html \
&&      chown www-data:www-data /var/www/html \
&&      chmod 777 /var/www/html \
&&      mkdir -p /usr/src \
&&      cd /usr/src \
&&      curl -fsSL -o php.tar.xz "$PHP_URL" \
&&      export \
            CFLAGS="$PHP_CFLAGS" \
            CPPFLAGS="$PHP_CPPFLAGS" \
            LDFLAGS="$PHP_LDFLAGS" \
&&      docker-php-source extract \
&&      cd /usr/src/php \
&&      gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
&&      ./configure \
            --build="$gnuArch" \
            --with-config-file-path="$PHP_INI_DIR" \
            --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
            --enable-option-checking=fatal \
            --with-mhash \
            --with-pic \
            --enable-mbstring \
            --with-password-argon2 \
            --with-sodium=shared \
            --with-curl \
            --with-libedit \
            --with-openssl \
            --with-zlib \
            --enable-fpm \
            --with-fpm-user=www-data \
            --with-fpm-group=www-data \
            --disable-cgi \
            --with-pear \
            --enable-mysqlnd \
            --enable-bcmath \
            --enable-intl \
            --enable-soap \
            --enable-opcache \
&&      make -j "$(expr $(nproc) / 3)" \
&&      find -type f -name '*.a' -delete \
&&      make install \
&&      find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true \
&&      make clean \
&&      cp -v php.ini-* "$PHP_INI_DIR/" \
&&      cd / \
&&      docker-php-source delete \
&&      runDeps="$( \
            scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
&&      apk add --no-cache $runDeps \
&&      pecl update-channels \
&&      rm -rf /tmp/pear ~/.pearrc \
&&      php --version \
&&      docker-php-ext-enable sodium \
&&      cd /usr/local/etc \
&&      sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null \
&&      cp php-fpm.d/www.conf.default php-fpm.d/www.conf \
&&      { \
            echo '[global]'; \
            echo 'error_log = /proc/self/fd/2'; \
            echo 'log_limit = 8192'; \
            echo; \
            echo '[www]'; \
            echo '; if we send this to /proc/self/fd/1, it never appears'; \
            echo 'access.log = /proc/self/fd/2'; \
            echo; \
            echo 'clear_env = no'; \
            echo; \
            echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
            echo 'catch_workers_output = yes'; \
            echo 'decorate_workers_output = no'; \
        } | tee php-fpm.d/docker.conf \
&&      { \
            echo '[global]'; \
            echo 'daemonize = no'; \
            echo; \
            echo '[www]'; \
            echo 'listen = 9000'; \
        } | tee php-fpm.d/zz-docker.conf \
&&      cp /usr/share/zoneinfo/Europe/Riga /etc/localtime \
&&      chmod uga+x /usr/local/bin/install-php-extensions \
&&      mkdir --parents --mode=777 --verbose /run/php-fpm \
&&      mkdir --parents /var/www/html/config \
&&      touch /run/php-fpm/.keep_dir \
&&      cat /home/www-data/installer | php -- --install-dir=/usr/local/bin --filename=composer \
&&      composer self-update --snapshot \
&&      chmod +x /usr/local/bin/pickle.phar \
&&      docker-php-source extract \
&&      pickle.phar install -n igbinary \
&&      docker-php-ext-enable igbinary \
&&      export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
&&      docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include/ \
&&      install-php-extensions imagick \
&&      pickle.phar install -n apcu \
&&      pickle.phar install -n inotify \
&&      pickle.phar install -n msgpack \
&&      pickle.phar install -n lzf \
&&      docker-php-ext-install pdo_pgsql pgsql gd zip \
&&      docker-php-ext-enable apcu gd imagick inotify msgpack opcache pdo_pgsql pgsql zip lzf \
&&      git clone https://github.com/phpredis/phpredis.git \
&&      ( \
            cd  phpredis \
            &&  phpize \
            &&  ./configure --enable-redis-igbinary --enable-redis-zstd --enable-redis-msgpack \
            &&  make -j "$(expr $(nproc) / 2)" \
            &&  make install \
        ) \
&&      docker-php-ext-enable redis \
&&      git clone https://github.com/k0d3r1s/phpiredis.git \
&&      ( \
            cd  phpiredis \
            &&  phpize \
            &&  ./configure --enable-phpiredis \
            &&  make -j "$(expr $(nproc) / 2)" \
            &&  make install \
        ) \
&&      docker-php-ext-enable phpiredis \
&&      docker-php-source delete \
&&      touch /var/www/html/config/preload.php \
&&      apk del --purge alpine-sdk argon2-dev autoconf coreutils curl-dev dpkg dpkg-dev file freetype-dev g++ gcc gnupg \
        hiredis-dev icu-dev imagemagick-dev libc-dev libedit-dev libjpeg-turbo-dev libpng-dev libsodium-dev \
        libwebp-dev libx11-dev libxau-dev libxdmcp-dev libxml2-dev libxpm-dev libzip-dev linux-headers oniguruma-dev \
        openssl-dev pcre-dev php8-dev php8-pear pkgconf postgresql-dev re2c sqlite-dev zstd-dev liblzf-dev \
&&      rm -rf \
        /home/www-data/installer \
        /home/www-data/phpredis \
        /home/www-data/phpiredis \
        /usr/local/bin/install-php-extensions \
        /usr/local/bin/pickle.phar \
        /usr/local/etc/php-fpm.conf \
        /usr/local/etc/php-fpm.d/* \
        /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
        /usr/local/etc/php/php.ini \
        /var/cache/apk/* \
        /tmp/pear

COPY    php-fpm.conf /usr/local/etc/php-fpm.conf
COPY    www.conf /usr/local/etc/php-fpm.d/www.conf
COPY    php.ini-development /usr/local/etc/php/php.ini
COPY    10-opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

WORKDIR /var/www/html

CMD     ["sh", "-c", "php-fpm -R && /bin/bash"]
