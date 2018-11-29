#!/bin/bash
# install script for http://wuhu.function.hu/

if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  exit
fi

# -------------------------------------------------
# set up the files / WWW dir

WUHU_ROOT=/var/www

chmod -R g+rw $WUHU_ROOT
chown -R www-data:www-data $WUHU_ROOT

echo "Fetching the latest Wuhu..."
git clone https://github.com/Gargaj/wuhu.git $WUHU_ROOT/

mkdir $WUHU_ROOT/entries_private
mkdir $WUHU_ROOT/entries_public
mkdir $WUHU_ROOT/screenshots

chmod -R g+rw $WUHU_ROOT/*
chown -R www-data:www-data $WUHU_ROOT/*

# -------------------------------------------------
# set up PHP

for i in /etc/php5/*/php.ini
do
  sed -i -e 's/^upload_max_filesize.*$/upload_max_filesize = 128M/' $i
  sed -i -e 's/^post_max_size.*$/post_max_size = 256M/' $i
  sed -i -e 's/^memory_limit.*$/memory_limit = 512M/' $i
  sed -i -e 's/^session.gc_maxlifetime.*$/session.gc_maxlifetime = 604800/' $i
  sed -i -e 's/^short_open_tag.*$/short_open_tag = On/' $i 
done

# -------------------------------------------------
# set up Apache

rm /etc/apache2/sites-enabled/*

echo -e \
  "<VirtualHost *:80>\n" \
  "\tDocumentRoot ${WUHU_ROOT}/www_party\n" \
  "\t<Directory />\n" \
  "\t\tOptions FollowSymLinks\n" \
  "\t\tAllowOverride All\n" \
  "\t</Directory>\n" \
  "\tErrorLog \${APACHE_LOG_DIR}/party_error.log\n" \
  "\tCustomLog \${APACHE_LOG_DIR}/party_access.log combined\n" \
  "\t</VirtualHost>\n" \
  "\n" \
  "<VirtualHost *:80>\n" \
  "\tDocumentRoot ${WUHU_ROOT}/www_admin\n" \
  "\tServerName admin.lan\n" \
  "\t<Directory />\n" \
  "\t\tOptions FollowSymLinks\n" \
  "\t\tAllowOverride All\n" \
  "\t</Directory>\n" \
  "\tErrorLog \${APACHE_LOG_DIR}/admin_error.log\n" \
  "\tCustomLog \${APACHE_LOG_DIR}/admin_access.log combined\n" \
  "</VirtualHost>\n" \
  > /etc/apache2/sites-available/wuhu.conf

a2ensite wuhu

echo "Restarting Apache..."
service apache2 restart

# -------------------------------------------------
# TODO? set up nameserver / dhcp?

# -------------------------------------------------
# set up MySQL

echo -e "Enter a MySQL password for the Wuhu user: \c"
WUHU_MYSQL_PASS=p0tat0es_ar3_fun

echo "Now connecting to MySQL..."
echo -e \
  "CREATE DATABASE wuhu;\n" \
  "GRANT ALL PRIVILEGES ON wuhu.* TO 'wuhu'@'%' IDENTIFIED BY '$WUHU_MYSQL_PASS';\n" \
  | mysql -u root -p 

# -------------------------------------------------
# We're done, wahey!

printf "\n\n\n*** CONGRATULATIONS, Wuhu is now ready to configure at http://admin.lan\n"
