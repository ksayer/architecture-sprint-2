#!/bin/bash

### Инициализируем config сервер
docker exec -t configSrv mongosh --port 27017 --eval '
rs.initiate({
  _id : "config_server",
  configsvr: true,
  members: [
    { _id : 0, host : "configSrv:27017" }
  ]
});
'

### Инициализируем реплику mongodb1
docker exec -t mongodb1 mongosh --port 27018 --eval '
rs.initiate({
  _id : "mongodb1",
  members: [
    { _id : 0, host : "mongodb1:27018" }
  ]
});
'

### Инициализируем реплику mongodb2
docker exec -t mongodb2 mongosh --port 27019 --eval '
rs.initiate({
  _id : "mongodb2",
  members: [
    { _id : 1, host : "mongodb2:27019" }
  ]
});
'

### без ожидания подключение к роутеру фейлится
sleep 5;

docker exec -t mongos_router mongosh --port 27020 --eval '
sh.addShard("mongodb1/mongodb1:27018");
sh.addShard("mongodb2/mongodb2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

db = db.getSiblingDB("somedb");
for (let i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({ age: i, name: "ly" + i });
}
'
