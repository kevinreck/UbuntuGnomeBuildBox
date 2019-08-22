
db.createUser({ user: "device_user" , pwd: "coleslaw", roles: [ {role: "readWrite", db: "CV_Device"}, {role: "userAdmin", db: "CV_Device"} ]})

db.createUser({ user: "mqtt" , pwd: "coleslaw", roles: [ {role: "readWrite", db: "cvMqttBroker"}, {role: "userAdmin", db: "cvMqttBroker"} ]})