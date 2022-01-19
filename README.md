# highload-sw-arch-hw-19

# Prerequisites
* docker
* linux + bash

# 1. Run MySQL master and 2 slaves, table users will be created and inserted in infinite loop on master server
```
./run.sh
```

# 2. Check tables on slave1 and slave2, everything should be replicated

```
docker exec mysql_slave1 sh -c "export MYSQL_PWD=111; mysql -u root -e 'USE mydb; SELECT * FROM users;'"
docker exec mysql_slave2 sh -c "export MYSQL_PWD=111; mysql -u root -e 'USE mydb; SELECT * FROM users;'"
```

# 3. Stop slave1, check that data on slave2 is replicated

```
docker-compose stop mysql_slave1
```

# 4. Drop column on slave1, check that replication is broken

```
Error 'Unknown column 'name' in 'field list'' on query. Default database: ''. Query: 'INSERT INTO mydb.users (name) VALUES ("name")'
```

# 5. Clean up
```
./cleanup.sh
```