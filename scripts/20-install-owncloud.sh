#!/bin/bash

# Install owncloud as a docker container. Configure it to include the calendar module

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Owncloud version to install
VERSION=9.1.2
# Image name prefix to use - default to hostname
IMAGENAME=$(hostname)/owncloud:$VERSION

# Path to resources folder (SCRIPT is only a temp variable)
SCRIPT=$(readlink -f "$0")
RESOURCE_LOCATION=$(dirname "$SCRIPT")/../resources

# Get the db root password if not already available
if [ -z $MYSQL_ROOT_PASSWORD ]; then
	echo "Enter the MySQL root password"
	read MYSQL_ROOT_PASSWORD
fi

# Ask for owncloud admin user name and password
echo "Enter the owncloud admin username"
read ADMIN_USER
echo "Enter the owncloud admin password"
read ADMIN_PASSWORD

# Create volumes
mkdir --parents /var/vol/owncloud/data
mkdir --parents /var/vol/owncloud/apps
mkdir --parents /var/vol/owncloud/config

# Fix ownership and permissions
chown --recursive www-data:www-data /var/vol/owncloud/data /var/vol/owncloud/apps /var/vol/owncloud/config
find /var/vol/owncloud -type d -printf '"%p" ' | xargs chmod 751
find /var/vol/owncloud -type f -printf '"%p" ' | xargs chmod 640
find /var/vol/owncloud/certs -type f -printf '"%p" ' | xargs chmod 644
find /var/vol/owncloud -name ".htaccess" | xargs chown root:www-data
find /var/vol/owncloud -name ".htaccess" | xargs chmod 644

# Build the docker image 
docker build --file "$RESOURCE_LOCATION/Dockerfile-owncloud" \
			--tag "$IMAGENAME" \
			--build-arg OCVERSION=$VERSION \
			"$RESOURCE_LOCATION"

# Run setup
docker run --network intercontainer \
		   --volume /var/vol/owncloud/data:/var/data/owncloud \
		   --volume /var/vol/owncloud/apps:/var/www/owncloud/apps \
		   --volume /var/vol/owncloud/config:/var/www/owncloud/config \
		   --name owncloud-config $IMAGENAME \
		   /bin/bash -c 'cd /var/www/owncloud && sudo -u www-data php occ  maintenance:install --database "mysql" --database-name "owncloud"  --database-user "root" --database-host "mysql" --database-pass "$MYSQL_ROOT_PASSWORD" --admin-user "$ADMIN_USER" --admin-pass "$ADMIN_PASSWORD" --data-dir "/var/data/owncloud"'

# Run it
docker run --detach \
           --restart=always \
           --network intercontainer \
           --publish 7080:7080 \
           --publish 7443:7443 \
           --volume /var/vol/owncloud/data:/var/data/owncloud \
           --volume /var/vol/owncloud/apps:/var/www/owncloud/apps \
           --volume /var/vol/owncloud/config:/var/www/owncloud/config \
           --name owncloud $IMAGENAME
