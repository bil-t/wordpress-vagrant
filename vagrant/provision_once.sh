#!/bin/bash -x
apt-get -qq update

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
	mkdir /vagrant/wordpress
	cd /vagrant/wordpress
	wget -q https://wordpress.org/latest.tar.gz
	tar -xzvf latest.tar.gz 
	cd wordpress
	cp wp-config-sample.php wp-config.php
fi
