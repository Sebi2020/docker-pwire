FROM php:7.2-fpm-stretch

LABEL Sebastian Tilders <info@informatikonline.net
# Install required files
RUN apt update && apt upgrade -y && apt install -y apache2 libmcrypt-dev libmagickwand-dev imagemagick libpng-dev libmcrypt4 && \
    pecl channel-update pecl.php.net && \
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini && \
    pecl config-set php_ini /usr/local/etc/php/php.ini && \
    pecl config-set ext_dir /usr/local/lib/php/extensions/no-debug-non-zts-20170718 && \
    pecl install mcrypt-snapshot && \
    pecl install imagick-stable && \
    pecl clear-cache && \
#    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) mysqli pdo_mysql gd opcache && \
    docker-php-ext-enable mcrypt && \
    docker-php-ext-enable imagick && \
    apt purge -y libpng-dev autoconf libmcrypt-dev libmagickwand-dev make gcc g++ && \
    apt autoremove -y && apt autoclean -y && \
    apt clean && \
    rm -rf /tmp/*
RUN apt update && apt install -y supervisor && apt clean && apt autoremove -y && apt autoclean -y && rm -rf /tmp/*

COPY ./*.sup.conf ./supervisor.conf /etc/supervisor/conf.d/
COPY ./exit.sh /exit.sh
COPY ./php7.2-fpm.conf /etc/apache2/conf-available/
RUN a2enconf php7.2-fpm && a2enmod proxy_fcgi rewrite
ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2

RUN mkdir -p $APACHE_RUN_DIR && mkdir -p $APACHE_LOCK_DIR && mkdir -p $APACHE_LOG_DIR 
EXPOSE 80 443

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
