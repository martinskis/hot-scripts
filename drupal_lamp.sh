#!/bin/bash

source <(curl -s http://169.254.169.254/2009-04-04/user-data)

function drush_install() {
cd /var/www/html/
drush dl drupal --destination=/var/www/ --drupal-project-rename=html -y
drush site-install standard --db-url='mysql://$DRUPAL_DB_USER:$DRUPAL_DB_USER_PASS@localhost/$DRUPAL_DB' --site-name=$SITE_NAME --account-name=$DRUPAL_USER --account-pass=$DRUPAL_PASS -y
chown -R apache.apache /var/www/html/
}

yum groupinstall -y "Web Server" "MySQL Database Client" "MySQL Database Server" "PHP Support"
yum install -y php-drush-drush wget

# make sure they are up on boot
chkconfig mysqld on
chkconfig httpd on

sed -ie '338s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# start the service
service httpd start
service mysqld start

# properties must be without special characters



mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "DROP DATABASE test"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

mysqladmin -u root -p"$DATABASE_PASS" create $DRUPAL_DB

mysql -u root -p"$DATABASE_PASS" -e "CREATE USER '$DRUPAL_DB_USER'@'localhost' IDENTIFIED BY '$DRUPAL_DB_USER_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON $DRUPAL_DB.* TO '$DRUPAL_DB_USER'@'localhost' IDENTIFIED BY '$DRUPAL_DB_USER_PASS';"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"


drush_install

