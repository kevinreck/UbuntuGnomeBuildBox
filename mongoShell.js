use CV_Device;
db.createUser({ user: "device_user" , pwd: "coleslaw", roles: ["readWrite", "userAdmin"]});

use cvMqttBroker;
db.createUser({ user: "mqtt" , pwd: "coleslaw", roles: ["readWrite", "userAdmin"]});