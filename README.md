
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

### TO-DO



# Icinga-DOCKER



		$ docker build https://github.com/ankh2054/icinga2-docker.git -t icinga
		
		


# Building the container 

		$ docker run  --name icinga --expose 80 \
		 -d -e "VIRTUAL_HOST=supermon.eos42.io" \
		 -e "LETSENCRYPT_HOST=supermon.eos42.io" \
		 -e "LETSENCRYPT_EMAIL=charles@eos42.io" \
		 -e 'DB_NAME=icinga' \
		 -e 'DB_USER=icinga' \
		 -e 'DB_PASS=icinga' \
		 -e 'DB_WEB_NAME=icingaweb' \
		 -e 'DB_WEB_USER=icingaweb' \
		 -e 'DB_WEB_PASS=icingaweb' \
		 -e 'DIRECTOR_USER=director' \
		 -e 'DIRECTOR_PASS=director_password' \
		 -e 'ROOT_PWD=password' \
		icinga



# NGINX-PROXY


nginx-proxy sets up a container running nginx and [docker-gen][1].  docker-gen generates reverse proxy configs for nginx and reloads nginx when containers are started and stopped.

See [Automated Nginx Reverse Proxy for Docker][2] for why you might want to use this.

### Nginx-proxy Usage - to enable SSL support

To use it with original [nginx-proxy](https://github.com/jwilder/nginx-proxy) container you must declare 3 writable volumes from the [nginx-proxy](https://github.com/jwilder/nginx-proxy) container:
* `/etc/nginx/certs` to create/renew Let's Encrypt certificates
* `/etc/nginx/vhost.d` to change the configuration of vhosts (needed by Let's Encrypt)
* `/usr/share/nginx/html` to write challenge files.

Example of use:

* First start nginx with the 3 volumes declared:
```bash
$ docker run -d -p 80:80 -p 443:443 \
    --name nginx-proxy \
    -v /path/to/certs:/etc/nginx/certs:ro \
    -v /etc/nginx/vhost.d \
    -v /usr/share/nginx/html \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
    jwilder/nginx-proxy
```
The "com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy" label is needed so that the letsencrypt container knows which nginx proxy container to use.

* Second start this container:
```bash
$ docker run -d \
    -v /path/to/certs:/etc/nginx/certs:rw \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --volumes-from nginx-proxy \
    jrcs/letsencrypt-nginx-proxy-companion
```

Then start any containers you want proxied with a env var `VIRTUAL_HOST=subdomain.youdomain.com`

    $ docker run -e "VIRTUAL_HOST=foo.bar.com" ..




[1]: https://github.com/etopian/docker-gen
[2]: http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/

