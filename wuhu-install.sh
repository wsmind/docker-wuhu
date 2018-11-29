#!/bin/bash
# install script for http://wuhu.function.hu/

if [ "$EUID" -ne 0 ]
then 
  echo "Please run as root"
  exit
fi

# -------------------------------------------------
# install mysql in a non-interactive way
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password plop'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password plop'
apt-get -y install mysql-server-5.5

# -------------------------------------------------
# set up the files / WWW dir

DATA_ROOT=/home/vagrant/app/data

mkdir $DATA_ROOT
mkdir $DATA_ROOT/entries_private
mkdir $DATA_ROOT/entries_public
mkdir $DATA_ROOT/screenshots
mkdir $DATA_ROOT/logs

usermod -a -G vagrant www-data

WUHU_ROOT=/var/www

# git will refuse to clone in a non-empty folder
rm -rf $WUHU_ROOT/*

echo "Fetching the latest Wuhu..."
git clone https://github.com/Gargaj/wuhu.git $WUHU_ROOT/

ln -s $DATA_ROOT/entries_private $WUHU_ROOT/entries_private
ln -s $DATA_ROOT/entries_public $WUHU_ROOT/entries_public
ln -s $DATA_ROOT/screenshots $WUHU_ROOT/screenshots
ln -s $DATA_ROOT/logs $WUHU_ROOT/logs

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
  "\tErrorLog ${WUHU_ROOT}/logs/party_error.log\n" \
  "\tCustomLog ${WUHU_ROOT}/logs/party_access.log combined\n" \
  "\t</VirtualHost>\n" \
  "\n" \
  "<VirtualHost *:80>\n" \
  "\tDocumentRoot ${WUHU_ROOT}/www_admin\n" \
  "\tServerName admin.lan\n" \
  "\t<Directory />\n" \
  "\t\tOptions FollowSymLinks\n" \
  "\t\tAllowOverride All\n" \
  "\t</Directory>\n" \
  "\tErrorLog ${WUHU_ROOT}/logs/admin_error.log\n" \
  "\tCustomLog ${WUHU_ROOT}/logs/admin_access.log combined\n" \
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
WUHU_MYSQL_PASS="p0tat0es_ar3_fun"

echo "Now connecting to MySQL..."
echo -e \
  "CREATE DATABASE wuhu;\n" \
  "GRANT ALL PRIVILEGES ON wuhu.* TO 'wuhu'@'%' IDENTIFIED BY '$WUHU_MYSQL_PASS';\n" \
  | mysql -u root -pplop

# -------------------------------------------------
# We're done, wahey!

printf "\n\n\n*** CONGRATULATIONS, Wuhu is now ready to configure at http://admin.lan\n"
