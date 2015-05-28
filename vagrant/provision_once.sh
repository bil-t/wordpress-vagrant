#!/bin/bash -x
apt-get -qq -y update
apt-get -qq -y install apache2
apt-get -qq -y install php5
apt-get -qq -y install php5-mysql

#install MySQL without prompt, hack try twice because the first attempts fails
for i in {1..2}
do
	debconf-set-selections <<< 'mysql-server mysql-server/root_password password '
	debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '
	apt-get -qq -y install mysql-server
done

#configure mysql database
DBUSER=wordpress
DBPASSWD=wordpress
DBNAME=WORDPRESS_DB
mysql -uroot -e "CREATE DATABASE $DBNAME"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $DBNAME.* to '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASSWD'"
mysql -uroot -e "FLUSH PRIVILEGES"

#install WordPress
if [ ! -d "/vagrant/wordpress" ]; then
	cd /vagrant
	wget -q https://wordpress.org/latest.tar.gz
	tar -xzvf latest.tar.gz 
	rm -f latest.tar.gz
	cd wordpress
	cp wp-config-sample.php wp-config.php	
	sed -i.bak -u "s/database_name_here/$DBNAME/g" wp-config.php
	sed -i.bak -u "s/username_here/$DBUSER/g" wp-config.php
	sed -i.bak -u "s/password_here/$DBPASSWD/g" wp-config.php	
	for i in {1..8}
	do
		NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
		sed -i.bak -u "0,/put your unique phrase here/s//$NEW_UUID/" wp-config.php		
	done
fi

#configure the apache web server to point to the wordpress directory
sed -i.bak -u 's,/var/www/html,/vagrant/wordpress,g' /etc/apache2/sites-available/000-default.conf

echo '<Directory /vagrant/wordpress>' >> /etc/apache2/apache2.conf
echo '	Options Indexes FollowSymLinks' >> /etc/apache2/apache2.conf
echo '	AllowOverride None' >> /etc/apache2/apache2.conf
echo '	Require all granted' >> /etc/apache2/apache2.conf
echo '</Directory>' >> /etc/apache2/apache2.conf

service apache2 restart

