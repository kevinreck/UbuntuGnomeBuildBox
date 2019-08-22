#!/usr/bin/env bash

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "NPM_TOKEN Required required, $# provided"

export NPM_TOKEN=$1

# set python virtual env default 
export VIRTUALENV_PYTHON=python3

# Dev
export CV_DB_HOST=127.0.0.1
export CV_DB_USER=root
export CV_DB_PASSWORD=coleslaw
export CV_MONGO_MQTT_PASS=coleslaw
export CV_MONGO_MQTT_PRIMARY_URL=127.0.0.1
export CV_MONGO_MQTT_USER=mqtt
export CV_MQTT_HOST=127.0.0.1
export CV_MONGO_DEVICE_USER=device_user
export CV_MONGO_DEVICE_PASS=coleslaw
export CV_MONGO_DEVICE_DB=CV_Device

# now write same settings to bashrc
tee -a ~/.bashrc > /dev/null << EOT

# set the NPM Token
export NPM_TOKEN=$1

# set python virtual env default 
export VIRTUALENV_PYTHON=python3

# Dev
export CV_DB_HOST=127.0.0.1
export CV_DB_USER=root
export CV_DB_PASSWORD=coleslaw
export CV_MONGO_MQTT_PASS=coleslaw
export CV_MONGO_MQTT_PRIMARY_URL=127.0.0.1
export CV_MONGO_MQTT_USER=mqtt
export CV_MQTT_HOST=127.0.0.1
export CV_MONGO_DEVICE_USER=device_user
export CV_MONGO_DEVICE_PASS=coleslaw
export CV_MONGO_DEVICE_DB=CV_Device
EOT

# load new environment vars
. ~/.bashrc

# Installing NVM
. ~/.nvm/nvm.sh
nvm install 9.9.0

# Install PM2 - node processing
npm install pm2@latest -g

mkdir repos
pushd repos

# Cloning initial repose
git clone git@github.com:Nautic-ON/deploy-gcp.git
git clone git@github.com:Nautic-ON/cv-backend-documentation.git

popd

# Startiong mySql, Mongo, and Redis
docker-compose -f ~/repos/cv-backend-documentation/scripts/local-docker-setup/docker-compose.yml up -d

# Logging into GCloud instance
gcloud auth login

# Setting up Mongo
mongo -u root -p password admin < ~/bin/mongodb.js 

# 
pushd repos/deploy-gcp/
./1-deploy-init.sh dev
./2-update-repos.sh

./a-create-initial-dbs.sh

popd

echo "Please run -- source ~./bashrc -- to load the enviornment variables"