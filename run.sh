#!/bin/bash

chmod 0444 ./master/conf/*
chmod 0444 ./slave1/conf/*
chmod 0444 ./slave2/conf/*

docker-compose up --build -d

until docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_user"@"%" IDENTIFIED BY "mydb_slave_pwd"; FLUSH PRIVILEGES;'
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$priv_stmt'"

echo "Enabled replication on master node"

until docker-compose exec mysql_slave1 sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave1 database connection..."
    sleep 4
done

until docker-compose exec mysql_slave2 sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave2 database connection..."
    sleep 4
done

docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='mydb_slave_user',MASTER_PASSWORD='mydb_slave_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'

echo $start_slave_cmd

docker exec mysql_slave1 sh -c "$start_slave_cmd"
docker exec mysql_slave1 sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"

docker exec mysql_slave2 sh -c "$start_slave_cmd"
docker exec mysql_slave2 sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"

create_table_stmt='USE mydb; CREATE TABLE users (id INTEGER(11) UNSIGNED AUTO_INCREMENT NOT NULL,name VARCHAR(255),PRIMARY KEY (id));'
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$create_table_stmt'"

insert_data_stmt='INSERT INTO mydb.users (name) VALUES ("name");'

while :
do
  docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$insert_data_stmt'"
  sleep 10
done