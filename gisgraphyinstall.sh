#!/bin/bash
# ========================================================================================================
# title          : gisgraphyinstall.sh
# description    : This script will automatically build a Gisgraphy server from a CentOS 7 minimal install
#                : Please refer to documentation on how to populate the database
# license        : GPLv3
# author         : Cory Hilliard
# date           : 2017.04.18
# version        : 4.2    
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

# download Java Development Kit version 7 update 79
wget --no-cookies \
--no-check-certificate \
--header "Cookie: oraclelicense=accept-securebackup-cookie" \
"http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jre-7u79-linux-x64.rpm"

# install Java Development Kit 7.79
yum install -y jre-7u79-linux-x64.rpm

# check to see if Oracle Java is now the default
java -version


# INSTALL POSTGRES ##################################################

# install postgresql repository
rpm -ivh https://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-3.noarch.rpm

# install PostgreSQL 9.5, PostGIS 2.2 and dependencies
yum install -y postgresql95 postgresql95-server postgresql95-libs postgresql95-contrib postgresql95-devel postgis2_95 postgis2_95-client

# initialize database
/usr/pgsql-9.5/bin/postgresql95-setup initdb

# start and enable PostgreSQL
systemctl enable postgresql-9.5
systemctl start  postgresql-9.5
systemctl status postgresql-9.5

# open firewall ports
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload


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

# create database
/usr/pgsql-9.5/bin/psql -c "CREATE DATABASE gisgraphy ENCODING = 'UTF8';"

# create language
/usr/pgsql-9.5/bin/createlang plpgsql gisgraphy

# create postgis Function
/usr/pgsql-9.5/bin/psql -d gisgraphy -f /usr/pgsql-9.5/share/contrib/postgis-2.2/postgis.sql

# Create spatial ref function
/usr/pgsql-9.5/bin/psql -d gisgraphy -f /usr/pgsql-9.5/share/contrib/postgis-2.2/spatial_ref_sys.sql

# add tables to the database
/usr/pgsql-9.5/bin/psql -d gisgraphy -f /var/lib/pgsql/gisgraphy/sql/create_tables.sql

# add users to the database
/usr/pgsql-9.5/bin/psql -d gisgraphy -f /var/lib/pgsql/gisgraphy/sql/insert_users.sql

EOF


# EDIT USER POSTGRES ###############################################

# run the following scripts as postgres: change password
sudo -i -u postgres bash <<'EOF'

# change the postgresql password in database
/usr/pgsql-9.5/bin/psql -d gisgraphy -c "ALTER USER postgres WITH PASSWORD 'password';"

EOF

# change password for user postgres
echo "postgres:password" | chpasswd

# backup postgres conf
mv /var/lib/pgsql/9.5/data/pg_hba.conf /var/lib/pgsql/9.5/data/pg_hba.conf.backup

# update postgres conf
cat > /var/lib/pgsql/9.5/data/pg_hba.conf <<'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     password
# IPv4 local connections
host    all             all             127.0.0.1/32            password
# IPv6 local connections
host    all             all             ::1/128                 password
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


