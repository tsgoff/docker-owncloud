owncloud
========

https://registry.hub.docker.com/u/bios/owncloud/

**Docker image to start a ownCloud container with CentOS, Nginx, fpm**

optional with linked MySQL/Postgres Container oder external MySQL. Default is SQLite.

Quickstart
----------

    docker run -d bios/owncloud
Now you habe a running ownCloud Container with SQLite

Options
-------

 - OC_RELATIV_URL_ROOT='/my/owncloud' 
 - FQDN='my.owncloud.tld'
 - SSL_SELFSIGNED='true'
 - SSL_PROTOCOLS='TLSv1 TLSv1.1 TLSv1.2'
 - SSL_CIPHERS='AES256+EECDH:AES256+EDH'
 - DB_PREFIX='oc_'
 - DB_HOST='mysql01.owncloud.tld'
 - DB_USER='owncloud'
 - DB_PASSWORD='mysecretpassword'
 - DB_NAME='owncloud'

Linking to MySQL Container
--------------------------

    docker run --name ownmysql -e MYSQL_ROOT_PASSWORD=mysecretpassword -d mysql
    docker run --name owncloud -d -e DB_PREFIX='oc_' \
    --link ownmysql:mysql bios/owncloud

Linking to PostgreSQL Container
-------------------------------

    docker run --name ownpostgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres
    docker exec ownpostgres sed -i '/IPv4 local connections/a host    all             all             172.17.42.1/32          trust' \
    /var/lib/postgresql/data/pg_hba.conf
    docker restart ownpostgres
    docker run --name owncloud -d -e DB_PREFIX='oc_' \
    --link ownpostgres:postgres bios/owncloud

External MySQL Server
---------------------
    docker run --name owncloud --dns 8.8.8.8 \
    -e DB_HOST='mysql01.owncloud.tld' \
    -e DB_USER='owncloud' \
    -e DB_PASSWORD='password' \
    -e DB_NAME='owncloud' \
    -e DB_PREFIX='_oc' \ -d bios/owncloud

Example
-------
Example with linked MySQL, SSL, custom path, custom SSL version / ciphers and custom FQDN

    docker run --name owncloud --dns 8.8.8.8 -d \
    -e SSL_SELFSIGNED='true' \
    -e DB_PREFIX='oc_' \
    -e SSL_PROTOCOLS='TLSv1 TLSv1.1 TLSv1.2' \
    -e SSL_CIPHERS='AES256+EECDH:AES256+EDH' \
    -e OC_RELATIV_URL_ROOT='/oc' \
    -e FQDN='my.hostname.tld' -p 443:443 --link ownmysql:mysql bios/owncloud
