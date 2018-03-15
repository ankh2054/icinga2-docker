
FROM alpine:3.7


# Install needed packages. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * musl: standard C library
#   * linux-headers: commonly needed, and an unusual package name from Alpine.
#   * build-base: used so we include the basic development packages (gcc)
#   * bash: so we can access /bin/bash - REMOVED to use build in busybox instead
#   * ca-certificates: for SSL verification during Pip and easy_install
#   * python: the binaries themselves
#   * python-dev: are used for gevent e.g.
#   * py-setuptools: required only in major version 2, installs easy_install so we can install Pip.
#   * mysql: Mysql server.
#   * mysql-client: Required for django to use mysql as database.
#   * supervisor: To autostart and ensure services stay running.
#   * mariadb-dev: Required by - pip install mysqlclient.
#   * nginx: To serve Django static content and proxy connections back to Django.

ENV PACKAGES="\
  dumb-init \
  musl \
  linux-headers \
  build-base \
  ca-certificates \
  php7 \ 
  icinga2 \
  monitoring-plugins \
  php7-intl \ 
  php7-imagick \ 
  php7-gd \ 
  php7-mysql \
  php7-curl \
  php7-mbstring \
  mysql \ 
  mysql-client\
  supervisor \
  mariadb-dev \
  curl \
  bind-tools \
  gnupg \
  mailutils \
  snmp \
  ssmtp \
  unzip \
  wget \
  nginx \ 
"


# apk update
RUN echo \
  # replacing default repositories with edge ones
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \


  && apk update \
  && apk add --no-cache $PACKAGES 


# Add files
ADD files/nginx.conf /etc/nginx/nginx.conf
ADD files/php-fpm.conf /etc/php/7.0/fpm/
ADD files/supervisord.conf /etc/supervisord.conf
ADD files/my.cnf /etc/mysql/my.cnf

# Final fixes
RUN true \
    && sed -i 's/vars\.os.*/vars.os = "Docker"/' /etc/icinga2/conf.d/hosts.conf 

# Entrypoint
ADD start.sh /
RUN chmod u+x /start.sh
CMD /start.sh
