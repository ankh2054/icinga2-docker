#!/bin/sh

# MYSQL SETUP 
#
# ###########


create_data_dir() {
  echo "Creating /var/lib/mysql"
  mkdir -p /var/lib/mysql
  chmod -R 0700 /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
}

create_run_dir() {
  echo "Creating /run/mysqld"
  mkdir -p /run/mysqld
  chmod -R 0755 /run/mysqld
  chown -R mysql:root /run/mysqld
}

create_log_dir() {
  echo "Creating /var/log/mysql"
  mkdir -p /var/log/mysql
  chmod -R 0755 /var/log/mysql
  chown -R mysql:mysql /var/log/mysql
}

mysql_default_install() {
  if [ ! -d "/var/lib/mysql/mysql" ]; then
      echo "Creating the default database"
      /usr/bin/mysql_install_db --datadir=/var/lib/mysql

  else
      echo "MySQL database already initialiazed"
  fi
}

create_database() {

  if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then

     # start mysql server.
      echo "Starting Mysql server"
      /usr/bin/mysqld_safe >/dev/null 2>&1 &

     # wait for mysql server to start (max 30 seconds).
      timeout=30
      echo -n "Waiting for database server to accept connections"
      while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
      do
        timeout=$(($timeout - 1))
        if [ $timeout -eq 0 ]; then
          echo -e "\nCould not connect to database server. Aborting..."
          exit 1
        fi
        echo -n "."
        sleep 1
      done
      echo
      
      # create database and assign user permissions.
      if [ -n "${DB_NAME}" -a -n "${DB_USER}" -a -n "${DB_PASS}" ]; then
         echo "Creating database \"${DB_NAME}\" and granting access to \"${DB_USER}\" database."
          mysql -uroot  -e  "CREATE DATABASE ${DB_NAME};"
          mysql -uroot  -e  "GRANT USAGE ON *.* TO ${DB_USER}@localhost IDENTIFIED BY '${DB_PASS}';"
          mysql -uroot  -e  "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO ${DB_USER}@localhost;"
          
         echo "Creating database \"${DB_WEB_NAME}\" and granting access to \"${DB_WEB_USER}\" database."
          mysql -uroot  -e  "CREATE DATABASE ${DB_WEB_NAME};"
          mysql -uroot  -e  "GRANT USAGE ON *.* TO ${DB_WEB_USER}@localhost IDENTIFIED BY '${DB_WEB_PASS}';"
          mysql -uroot  -e  "GRANT ALL PRIVILEGES ON ${DB_WEB_NAME}.* TO ${DB_WEB_USER}@localhost;"
         
         echo "Creating director database and granting access"
          mysql -uroot -e "CREATE DATABASE director CHARACTER SET 'utf8';"
          mysql -uroot -e "GRANT ALL ON director.* TO director@localhost IDENTIFIED BY '${DB_WEB_PASS}';"

          
         echo "Imporing Icinga ido modules"
          mysql -u root ${DB_NAME} <  /usr/share/icinga2-ido-mysql/schema/mysql.sql

      else
        echo "How have not provided all the required ENV variabvles to configure the database"

      fi
  else 
      echo "Database \"${DB_NAME}\" already exists"

  fi
  
}

db_ido_mysql(){
# Creating icinga MYSQL connection file.
echo "Creating icinga MYSQL connection file"
cat > /etc/icinga2/features-available/ido-mysql.conf<<EOF
library "db_ido_mysql"

object IdoMysqlConnection "mysql-ido" {
  host = "127.0.0.1"
  port = 3306
  user = "${DB_USER}"
  password = "${DB_PASS}"
  database = "${DB_NAME}"

  cleanup = {
    downtimehistory_age = 48h
    contactnotifications_age = 31d
  }
}
EOF
cp /etc/icinga2/features-available/ido-mysql.conf /etc/icinga2/features-enabled/ido-mysql.conf
}

set_mysql_root_pw() {
    # Check if root password has already been set.
    r=`/usr/bin/mysqladmin -uroot  status`
    if [ ! $? -ne 0 ] ; then
      echo "Setting Mysql root password"
      /usr/bin/mysqladmin -u root password "${ROOT_PWD}"

      # shutdown mysql reeady for supervisor to start mysql.
      timeout=10
      echo "Shutting down Mysql ready for supervisor"
      /usr/bin/mysqladmin -u root --password=${ROOT_PWD} shutdown
      
      else 
       echo "Mysql root password already set"
    fi
    
}


update_php_ini(){
   # Updating some default PHP values
  echo "Change default php.ini values"
  sed -i "s/^;date.timezone =$/date.timezone = \"Europe\/London\"/" /etc/php7/php.ini |grep "^timezone" /etc/php7/php.ini
 }

icinga_configure(){

  # Prepare directories for Icinga2 & Add nginx uyser to icingabwe2 GROUP
  echo "Prepating icinga directories"
  chmod u+x /tmp/prepare-dirs.sh && /tmp/prepare-dirs.sh /etc/icinga2/icinga2.sysconfig
  /usr/share/webapps/icingaweb2/bin/icingacli setup config directory --group icingaweb2;
  echo "add nginx to icingaweb2 group"
  adduser nginx icingaweb2
  icinga2 api setup
  echo "Take a note of this password, for the setup later"
  cat /etc/icinga2/conf.d/api-users.conf

}

icinga_director(){
git clone https://github.com/Icinga/icingaweb2-module-director /usr/share/webapps/icingaweb2/modules/director

echo "Create director resource"
cat << EOF | tee -a /etc/icingaweb2/resources.ini

[icinga_director]
type = "db"
db = "mysql"
host = "localhost"
port = "3306"
dbname = "director"
username = "director"
password = "${DB_WEB_PASS}"
charset = "UTF8"
persistent = "0"
EOF

echo "Create director kickstart"
cat << EOF | tee -a /etc/icingaweb2/modules/director/kickstart.ini
[config]
endpoint = ${VIRTUAL_HOST}
host = 127.0.0.1
port = 5665
username = director
password = 
EOF


echo "Creating director API user"
cat > /etc/icinga2/conf.d/icinga2-api-user.conf<<EOF
  object ApiUser "${DIRECTOR_USER}" {
    password = "${DIRECTOR_PASS}"
    permissions = [ "*" ]
  }
EOF


echo "Enable director module"
icingacli module enable director

}

create_data_dir
create_run_dir
create_log_dir
mysql_default_install
create_database
db_ido_mysql
set_mysql_root_pw
update_php_ini
icinga_configure
icinga_director



# Start Supervisor 
echo "Starting Supervisor"
/usr/bin/supervisord -n -c /etc/supervisord.conf
