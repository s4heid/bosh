#!/bin/bash

set -euo pipefail
set -x

# export DB="mysql"

rm -rf blobs/
bosh sync-blobs

( cd src/ && \
  rm -rf ./tmp && \
  rm -rf vendor/cache/*.gem && \
  bundle config set --local path ./vendor/cache && \
  bundle install && \
  bundle exec rake spec:integration:download_bosh_agent && \
  bundle exec rake spec:integration:install_dependencies
)


# echo "Starting $DB..."
# case "$DB" in
#   mysql)
#     export DB_USER="root"
#     export DB_PASSWORD="password"
#     export DB_PORT="3306"
#     # if [ ! -d /var/lib/mysql-src ]; then # Set up MySQL if it's the first time
#     #   mv /var/lib/mysql /var/lib/mysql-src
#     #   mkdir -p /var/lib/mysql
#     #   mount -t tmpfs -o size=512M tmpfs /var/lib/mysql
#     #   mv /var/lib/mysql-src/* /var/lib/mysql/
#     # fi
#     echo '
# [client]
# default-character-set=utf8

# [mysql]
# default-character-set=utf8

# [mysqld]
# collation-server = utf8_unicode_ci
# init-connect='SET NAMES utf8'
# character-set-server = utf8
# sql-mode="STRICT_TRANS_TABLES"
# skip-log-bin
# max_connections = 1024' >> /etc/mysql/my.cnf

#     echo "....... DB TLS enabled ......."

#     export MYSQLDIR=/var/lib/mysql
#     # mkdir -p $MYSQLDIR
#     cp ./src/bosh-dev/assets/sandbox/database/database_server/private_key $MYSQLDIR/server-key.pem
#     cp ./src/bosh-dev/assets/sandbox/database/database_server/certificate.pem $MYSQLDIR/server-cert.pem
#     echo '
# ssl-cert=server-cert.pem
# ssl-key=server-key.pem
# require_secure_transport=ON
# max_allowed_packet=6M' >> /etc/mysql/my.cnf

#     service mysql start
#     sleep 5
#     mysql -h 127.0.0.1 \
#           -P ${DB_PORT} \
#           --user=${DB_USER} \
#           --password=${DB_PASSWORD} \
#           -e 'create database uaa;' > /dev/null 2>&1
#     ;;
#   postgresql)
#     export PATH=/usr/lib/postgresql/$DB_VERSION/bin:$PATH
#     export DB_USER="postgres"
#     export DB_PASSWORD="smurf"
#     export DB_PORT="5432"
#     export PGPASSWORD=${DB_PASSWORD}

#     if [ ! -d /tmp/postgres ]; then # PostgreSQL hasn't been set up
#       mkdir /tmp/postgres
#       mount -t tmpfs -o size=512M tmpfs /tmp/postgres
#       mkdir /tmp/postgres/data
#       chown postgres:postgres /tmp/postgres/data
#       export PGDATA=/tmp/postgres/data

#       su -m postgres -c '
#         export PATH=/usr/lib/postgresql/$DB_VERSION/bin:$PATH
#         export PGDATA=/tmp/postgres/data
#         export PGLOGS=/tmp/log/postgres
#         mkdir -p $PGDATA
#         mkdir -p $PGLOGS
#         echo $DB_PASSWORD > /tmp/bosh-postgres.password
#         initdb -U postgres -D $PGDATA --pwfile /tmp/bosh-postgres.password
#       '

#       echo "max_connections = 1024" >> $PGDATA/postgresql.conf
#       echo "shared_buffers = 240MB" >> $PGDATA/postgresql.conf

#       echo "....... DB TLS enabled ......."
#       cp ./src/bosh-dev/assets/sandbox/database/database_server/private_key $PGDATA/server.key
#       cp ./src/bosh-dev/assets/sandbox/database/database_server/certificate.pem $PGDATA/server.crt
#       chown postgres $PGDATA/server.key
#       chown postgres $PGDATA/server.crt
#       su postgres -c '
#         export PGDATA=/tmp/postgres/data
#         echo "ssl = on" >> $PGDATA/postgresql.conf
#         echo "client_encoding = 'UTF8'" >> $PGDATA/postgresql.conf
#         echo "hostssl all all 127.0.0.1/32 password" > $PGDATA/pg_hba.conf
#         echo "hostssl all all 0.0.0.0/32 password" >> $PGDATA/pg_hba.conf
#         echo "hostssl all all ::1/128 password" >> $PGDATA/pg_hba.conf
#         echo "hostssl all all localhost password" >> $PGDATA/pg_hba.conf

#         chmod 600 $PGDATA/server.*
#       '

#       su postgres -c '
#         export PATH=/usr/lib/postgresql/$DB_VERSION/bin:$PATH
#         export PGLOGS=/tmp/log/postgres
#         export PGCLIENTENCODING=UTF8
#         pg_ctl start -l $PGLOGS/server.log -o "-N 400" --wait
#         createdb -h 127.0.0.1 uaa
#       '
#     fi
#     ;;
#   *)
#     echo "Usage: DB={mysql|postgresql} $0 {commands}"
#     exit 1
# esac