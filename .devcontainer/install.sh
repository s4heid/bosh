#!/bin/bash

set -euo pipefail
set -x

sudo apt-get update -y \
  && apt-get install -y --no-install-recommends \
    mysql-server \
  && usermod -d /var/lib/mysql/ mysql

( cd src/ && \
  gem install bundler && \
  bundle install
)

export MYSQL_ROOT=/var/lib/mysql
cp ./src/bosh-dev/assets/sandbox/database/database_server/private_key "${MYSQL_ROOT}/server.key"
cp ./src/bosh-dev/assets/sandbox/database/database_server/certificate.pem "${MYSQL_ROOT}/server.cert"
{
  echo "[client]"
  echo "default-character-set=utf8"
  echo "[mysql]"
  echo "default-character-set=utf8"

  echo "[mysqld]"
  echo "collation-server = utf8_unicode_ci"
  echo "init-connect='SET NAMES utf8'"
  echo "character-set-server = utf8"
  echo 'sql-mode="STRICT_TRANS_TABLES"'
  echo "skip-log-bin"
  echo "max_connections = 1024"

  echo "ssl-cert=server.cert"
  echo "ssl-key=server.key"
  echo "require_secure_transport=OFF"
  echo "max_allowed_packet=6M"
} >> /etc/mysql/my.cnf

sudo service mysql start
sleep 5
sudo service mysql status

mysql -h localhost \
      -P ${DB_PORT} \
      --user=${DB_USER} \
      -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"

mysql -h localhost \
      -P ${DB_PORT} \
      --user=${DB_USER} \
      --password=${DB_PASSWORD} \
      -e 'create database uaa;' > /dev/null 2>&1

echo "Your bosh environment is set up."
echo "You can now run the tests with:"
echo "  cd src"
echo "  bundle exec rake spec:unit"
echo "  bundle exec rake spec:integration"
