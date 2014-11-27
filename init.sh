#!/bin/sh


FILE=autoconfig.php
PATH=/usr/share/nginx/owncloud/config/
SSL_PROTOCOLS_DEFAULT='SSLv2 TLSv1'
SSL_CIPHERS_DEFAULT='ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP'

if [ -z "$OC_RELATIV_URL_ROOT" ]; then
        echo "install in Document Root"
else
        echo "path to oc: $OC_RELATIV_URL_ROOT"
        /bin/mv /usr/share/nginx/owncloud/ /usr/share/nginx/RWlzYW9iYWluZzBpZXNoCg
        /bin/mkdir -p /usr/share/nginx/owncloud/$OC_RELATIV_URL_ROOT
        /bin/mv /usr/share/nginx/RWlzYW9iYWluZzBpZXNoCg/* /usr/share/nginx/RWlzYW9iYWluZzBpZXNoCg/.??* /usr/share/nginx/owncloud/$OC_RELATIV_URL_ROOT
        /bin/rm -rf /usr/share/nginx/RWlzYW9iYWluZzBpZXNoCg
        PATH=/usr/share/nginx/owncloud/$OC_RELATIV_URL_ROOT/config/
        #/bin/sed -i "s@owncloud@owncloud$OC_RELATIV_URL_ROOT@g" /etc/nginx/conf.d/default.conf
        /bin/chown -R nginx:nginx /usr/share/nginx/owncloud/ 
        /bin/echo "<?php header(\"Location: $OC_RELATIV_URL_ROOT\"); die(); ?>" > /usr/share/nginx/owncloud/index.php

fi

if [ -z "$MYSQL_ENV_MYSQL_ROOT_PASSWORD" ]; then
        echo "no linked mysql detected" 
else
        echo "linked mysql detected with container id $HOSTNAME and version $MYSQL_ENV_MYSQL_VERSION"
        DB_TYPE=link_mysql
fi

if [ -z "$POSTGRES_ENV_POSTGRES_PASSWORD" ]; then
        echo "no linked postgresql detected"
else
        echo "linked postgresql detected with container id $HOSTNAME and version $POSTGRES_ENV_PG_VERSION"
        DB_TYPE=link_postgresql
fi

if [ -z "$DB_HOST" ]; then
        echo "no external mysql detected"
else
        echo "external mysql detected"
        DB_TYPE=ext_mysql
fi

/bin/mkdir /data
/bin/chown nginx:nginx /data

function fixperm {
       /bin/chown nginx:nginx $PATH$FILE
}

case $DB_TYPE in
    sqlite)
        echo 'using local sqlite'
        /bin/cat >$PATH$FILE <<EOL
<?php
\$AUTOCONFIG = array(
  "directory"     => "/data",
  "dbtype"        => "sqlite",
  "dbname"        => "owncloud",
  "dbtableprefix" => "$DB_PREFIX",
);
EOL
        ;;
    link_mysql)
        echo 'using linked mysql'
        MYSQL_HOST=`echo $MYSQL_NAME | /bin/awk -F "/" '{print $3}'`
        echo "MySQL host is $MYSQL_HOST"
	if [ -z "$MYSQL_USER" ]; then
        	echo "set MySQL user default to: root"
        	MYSQL_USER=root
	fi
        /bin/cat >$PATH$FILE <<EOL
<?php
\$AUTOCONFIG = array(
  "directory"     => "/data",
  "dbtype"        => "mysql",
  "dbname"        => "owncloud",
  "dbuser"        => "$MYSQL_USER",
  "dbpass"        => "$MYSQL_ENV_MYSQL_ROOT_PASSWORD",
  "dbhost"        => "$MYSQL_HOST",
  "dbtableprefix" => "$DB_PREFIX",
);
EOL
        fixperm
        ;;
    link_postgresql)
        echo 'using linked postgresql'
        POSTGRESQL_HOST=`echo $POSTGRES_NAME | /bin/awk -F "/" '{print $3}'`
        echo "PostgreSQL host is $POSTGRESQL_HOST"
        if [ -z "$POSTGRESQL_USER" ]; then
                echo "set PostgreSQL user default to: postgres"
                POSTGRESQL_USER=postgres
        fi
        if [ -z "$DB_NAME" ]; then
                echo "set PostgreSQL Database Name to: postgres"
                DB_NAME=postgres
        fi
        /bin/cat >$PATH$FILE <<EOL
<?php
\$AUTOCONFIG = array(
  "directory"     => "/data",
  "dbtype"        => "pgsql",
  "dbname"        => "$DB_NAME",
  "dbuser"        => "$POSTGRESQL_USER",
  "dbpass"        => "$POSTGRES_ENV_POSTGRES_PASSWORD",
  "dbhost"        => "$POSTGRESQL_HOST",
  "dbtableprefix" => "$DB_PREFIX",
);
EOL
        fixperm
        ;;
    ext_mysql)
        echo 'using external MYSQL DB'
        /bin/cat >$PATH$FILE <<EOL
<?php
\$AUTOCONFIG = array(
  "directory"     => "/data",
  "dbtype"        => "mysql",
  "dbname"        => "$DB_NAME",
  "dbuser"        => "$DB_USER",
  "dbpass"        => "$DB_PASSWORD",
  "dbhost"        => "$DB_HOST",
  "dbtableprefix" => "$DB_PREFIX",
);
EOL
        fixperm
        ;;
    *)
        echo "no database specified"
        #exit 1
esac


if [ -z "$FQDN" ]; then
        echo "no fqdn"
        FQDN="own.cloud"
else
        echo "found fqdn $FQDN"
        /bin/sed -i "s@server_name  _@server_name  $FQDN@g" /etc/nginx/conf.d/default.conf 
fi


if [ -z "$SSL_SELFSIGNED" ]; then
        echo "no SSL"
else
        echo "generating selfsigned cert"
        if [ -z "$SSL_PROTOCOLS" ]; then
              echo "set default SSL protocol"
              SSL_PROTOCOLS=$SSL_PROTOCOLS_DEFAULT
        fi
        if [ -z "$SSL_CIPHERS" ]; then
              echo "set default SSL ciphers"
              SSL_CIPHERS=$SSL_CIPHERS_DEFAULT
        fi

/bin/mkdir /etc/nginx/ssl/
/bin/chown nginx:nginx /etc/nginx/ssl/

### <--
        /usr/bin/openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt <<SSL


 ownCity


 $FQDN

SSL
### -->

/bin/cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/ssl.conf
/bin/sed -i "s@listen       80 default_server@listen       443@g" /etc/nginx/conf.d/ssl.conf
/bin/sed -i '/server_name/a\\n    ssl                  on; \n\
    ssl_certificate      /etc/nginx/ssl/nginx.crt;\n    ssl_certificate_key  /etc/nginx/ssl/nginx.key;\n\
    ssl_session_timeout  5m;\n\n    ssl_protocols  '"$SSL_PROTOCOLS"';\
    ssl_ciphers  '"$SSL_CIPHERS"';\
    ssl_prefer_server_ciphers   on;'  /etc/nginx/conf.d/ssl.conf

fi


/usr/sbin/php-fpm -F &
/usr/sbin/nginx -c /etc/nginx/nginx.conf

wait
