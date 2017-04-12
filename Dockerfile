FROM ubuntu:16.04
MAINTAINER Kimtaek <jinze1991@icloud.com>

RUN DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_US.UTF-8

ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

RUN apt-get update && apt-get dist-upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

# Install "software-properties-common" (for the "add-apt-repository")
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F2A61FE5

# Add the "PHP 7" ppa
RUN add-apt-repository 'deb http://us.archive.ubuntu.com/ubuntu/ yakkety main restricted universe multiverse'
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:ondrej/php

# Install Mysql
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections \
    && echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections \
    && apt-get install -y mariadb-server

# Install Redis, Nginx, Mongo
RUN apt-get update && apt-get -y --force-yes install nginx redis-server supervisor \
    && mkdir -p /data/db

# Install PHP-CLI 7, some PHP extentions and some useful Tools with APT
RUN apt-get install -y --force-yes \
        php7.1 \
        php7.1-fpm \
        php7.1-dev \
        php7.1-cli \
        php7.1-common \
        php7.1-intl \
        php7.1-bcmath \
        php7.1-mbstring \
        php7.1-soap \
        php7.1-xml \
        php7.1-zip \
        php7.1-apcu \
        php7.1-json \
        php7.1-gd \
        php7.1-curl \
        php7.1-mcrypt \
        php7.1-mysql \
        php7.1-sqlite \
        php7.1-memcached \
        php7.1-xdebug \
        git \
        curl \
        vim

# remove load xdebug extension (only load on phpunit command)
RUN sed -i 's/^/;/g' /etc/php/7.1/fpm/conf.d/20-xdebug.ini

# Install Composer
RUN curl -s http://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

WORKDIR /www

EXPOSE 80 443 9001 3306 6379

ADD storage/docker/startup.sh /opt/bin/startup.sh
RUN chmod u=rwx /opt/bin/startup.sh

RUN sed -e '29d' < /etc/mysql/mariadb.conf.d/50-server.cnf >> /etc/mysql/mariadb.conf.d/server.cnf
RUN rm -rf /etc/mysql/mariadb.conf.d/50-server.cnf

#COPY default.conf /etc/nginx/sites-available/default
COPY storage/docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/opt/bin/startup.sh"]
