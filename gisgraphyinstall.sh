#!/bin/bash
# ========================================================================================================
# title          : gisgraphyinstall.sh
# description    : This script will NOT automatically build a Gisgraphy server from a CentOS 7 minimal install
#                : Please refer to documentation on how to populate the database
# license        : GPLv3
# author         : Fakieh Maulana
# date           : 8/21/2020
# version        : 5.0.0  
# usage          : bash gisgraphyinstall.sh
# ========================================================================================================

# CentOS 7 ENVIRONMENT SETUP ########################################

# update Server
yum update -y

# install extra packages for enterprise Linux
yum install -y epel-release

# install wget and unzip if install of CentOS 7 - Minimal
yum install -y wget unzip


# INSTALL JAVA ######################################################

# change to root directory
cd /root

# download Java Development Kit version 8
yum install java-1.8.0-openjdk

# check to see if Oracle Java is now the default
java -version

# update-alternatives
update-alternatives --config java

# After copying your Java’s path, open the .bash_profile with your text editor.

vim .bash_profile

# Export your Java path into the .bash_profile by adding the following to the bottom of the file. (Your path may look different from mine, and it’s not important that they vary.)

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.191.b12-1.el7_6.x86_64/jre/bin/java

# Refresh the File:

source .bash_profile

# When you use the JAVA_HOME variable you’ll now be able to see the path you set.

echo $JAVA_HOME


# INSTALL POSTGRES ##################################################

# install postgresql repository
sudo rpm -Uvh https://yum.postgresql.org/10/redhat/rhel-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum --disablerepo="*" --enablerepo="pgdg10" list available

# install PostgreSQL 10, PostGIS 2.5 and dependencies
yum install -y postgresql10 postgresql10-server postgresql10-libs postgresql10-contrib postgresql10-devel postgis

# initialize database
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb

# start and enable PostgreSQL
systemctl restart postgresql-10.service
systemctl enable postgresql-10.service
systemctl status postgresql-10.service

# open firewall ports
#firewall-cmd --permanent --add-port=5432/tcp
#firewall-cmd --permanent --add-port=80/tcp
#firewall-cmd --permanent --add-port=8080/tcp
#firewall-cmd --reload
systemctl kill firewalld
systemctl disable firewalld

# INSTALL GISGRAPHY ################################################

# change to root directory
cd /root

# download Gisgraphy
wget http://download.gisgraphy.com/releases/gisgraphy-4.0-beta1.zip

# unpack gisgraphy to the proper folder
unzip gisgraphy-4.0-beta1.zip -d /var/lib/pgsql/

# rename folder
mv /var/lib/pgsql/gisgraphy-4.0-beta1 /var/lib/pgsql/gisgraphy

# set ownership of folder to postgres user
chown postgres:postgres -R /var/lib/pgsql/gisgraphy

# running some commands as the postgres user
sudo -i -u postgres bash <<'EOF'

# create the database
psql -c  "CREATE DATABASE gisgraphy ENCODING = 'UTF8';"

# create language
createlang -U postgres -h localhost plpgsql gisgraphy 

# create postgis Function
psql -U postgres -h localhost -d gisgraphy -f /usr/pgsql-10/share/contrib/postgis-2.4/postgis.sql

# Create spatial ref function
psql -U postgres -h localhost -d gisgraphy -f /usr/pgsql-10/share/contrib/postgis-2.4/spatial_ref_sys.sql

# add tables to the database
psql -U postgres -h localhost -d gisgraphy -f /var/lib/pgsql/gisgraphy/sql/create_tables.sql

# add users to the database
psql -U postgres -h localhost -d gisgraphy -f /var/lib/pgsql/gisgraphy/sql/insert_users.sql

EOF


# EDIT USER POSTGRES ###############################################

# run the following scripts as postgres: change password
sudo -i -u postgres bash <<'EOF'

# change the postgresql password in database
psql -U postgres -h localhost -d gisgraphy -c "ALTER USER postgres WITH PASSWORD 'password';"

EOF

# change password for user postgres
echo "postgres:password" | chpasswd

# backup postgres conf
mv /var/lib/pgsql/9.5/data/pg_hba.conf /var/lib/pgsql/9.5/data/pg_hba.conf.backup

# update postgres conf
cat > /var/lib/pgsql/9.5/data/pg_hba.conf <<'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
#host    all             all             127.0.0.1/32            ident
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
#host    all             all             ::1/128                 ident
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     all                                     peer
#host    replication     all             127.0.0.1/32            ident
#host    replication     all             ::1/128                 ident
EOF

# restart postgres
systemctl restart postgresql-9.5

# add password to jdbc.properties
sed -i '26s/jdbc.password=/jdbc.password=password/' /var/lib/pgsql/gisgraphy/webapps/ROOT/WEB-INF/classes/jdbc.properties
sed -i '32s/hibernate.connection.password=/hibernate.connection.password=password/' /var/lib/pgsql/gisgraphy/webapps/ROOT/WEB-INF/classes/jdbc.properties
cat /var/lib/pgsql/gisgraphy/webapps/ROOT/WEB-INF/classes/jdbc.properties

# PREPARE GISGRAPHY SHELL SCRIPTS #################################################

# make shell scripts executable
chmod +x /var/lib/pgsql/gisgraphy/*.sh


# LAUNCH GISGRAPHY #################################################

# change to gisgraphy folder
cd /var/lib/pgsql/gisgraphy/

# launch gisgraphy
#./launch.sh
localhost:8080/mainMenu.html
login:
admin
admin


fix:
Error : An error occurred when processing GeonamesCountryImporter : An error occurred when processing countryInfo.txt : An Error occurred on Line 1 for AD	AND	020	AN	Andorra	Andorra la Vella	468	84000	EU	.ad	EUR	Euro	376	AD###	^(?:AD)*(\d{3})$	ca	3041565	ES,FR	: IllegalArgumentException occurred while calling setter of com.gisgraphy.domain.geoloc.entity.GisFeature.adm; nested exception is org.hibernate.PropertyAccessException: IllegalArgumentException occurred while calling setter of com.gisgraphy.domain.geoloc.entity.Gis

replace jar on:
/var/lib/pgsql/gisgraphy/webapps/ROOT/WEB-INF/lib/

spring-beans-4.3.5.RELEASE.jar
spring-core-4.3.5.RELEASE.jar
spring-jcl-4.3.5.RELEASE.jar
spring-jdbc-4.3.5.RELEASE.jar
spring-tx-4.3.5.RELEASE.jar

postgresql-8.1-407.jdbc3.jar

by their updated versions:

spring-beans-5.0.4.RELEASE.jar
spring-core-5.0.4.RELEASE.jar
spring-jcl-5.0.4.RELEASE.jar
spring-jdbc-5.0.4.RELEASE.jar
spring-tx-5.0.4.RELEASE.jar

postgresql-42.2.2.jar


