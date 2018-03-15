
FROM alpine:3.7



ENV PACKAGES="\
  dumb-init \
  musl \
  linux-headers \
  build-base \
  ca-certificates \
  php \ 
  icinga2 \
  monitoring-plugins \
  php-intl \ 
  php-imagick \ 
  php-gd \ 
  php-mysql \
  php-curl \
  php-mbstring \
  mysql \ 
  mysql-client\
  supervisor \
  mariadb-dev \
  curl \
  dnsutils \
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
