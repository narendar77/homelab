#!/bin/sh
#
# check if docker is running
if ! (docker ps >/dev/null 2>&1)
then
	echo "docker daemon not running, will exit here!"
	exit
fi
echo "Preparing folder init and creating ./init/initdb.sql"
mkdir ./init >/dev/null 2>&1
chmod -R +x ./init
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > ./init/initdb.sql
echo "done"
echo "Preparing folder record and set permissions"
mkdir ./record >/dev/null 2>&1
chmod -R 777 ./record
echo "done"
echo "Guacamole setup complete!"
echo "Run 'chmod +x prepare.sh' and then './prepare.sh' to initialize the database."
echo "You can then start the services with 'docker-compose up -d'."
echo "Access Guacamole at http://localhost:8080/guacamole"
echo "Default credentials: guacadmin/guacadmin"
echo "Database: guacamole_db"
echo "MySQL root password: rootpassword"
echo "MySQL guacamole user password: guacamolepassword"
echo "Docker volumes will be created in ./volumes/"
echo "Make sure to set proper permissions on the init directory after running this script."
echo "The initdb.sql file has been generated in ./init/initdb.sql"
echo "You can now run 'docker-compose up -d' to start the services."
echo "Remember to set proper permissions on the init directory after running this script."
echo "To initialize the database, run: docker-compose run --rm guacd initdb"
echo "To view logs: docker-compose logs -f"
echo "To stop the services: docker-compose down"
echo "To clean up: docker-compose down -v"
echo "To view running containers: docker ps"
echo "To view container logs: docker logs <container_name>"