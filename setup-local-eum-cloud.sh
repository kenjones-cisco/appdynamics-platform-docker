#!/bin/bash

PORT=3388
USER=controller
PASS=controller
DB=controller

CONTROLLER_HOME="/appdynamics/Controller"
MY_SQL_HOME=$CONTROLLER_HOME/db/bin

function execMySQL {
	echo "$1" | ${MY_SQL_HOME}/mysql --port=$PORT -u $USER --password=$PASS --database=$DB | tail -1
}

UPDATE_QUERY_BEACON_HOST="UPDATE controller.global_configuration_cluster SET value='$EUM_BEACON_HOST' WHERE name='appdynamics.controller.eum.cloud.hostname';"
UPDATE_QUERY_CLOUD_HOST="UPDATE controller.global_configuration_cluster SET value='$EUM_CLOUD_HOST' WHERE name='appdynamics.controller.eum.beacon.hostname';"

EUM_CLOUD_HOST="localhost:7001"
EUM_BEACON_HOST="localhost:7001"

# Update server store to use local store key
execMySQL "$UPDATE_QUERY_CLOUD_HOST"
execMySQL "$UPDATE_QUERY_BEACON_HOST"

echo "appdynamics.controller.eum.cloud.hostname: $EUM_CLOUD_HOST"
echo "appdynamics.controller.eum.beacon.hostname: $EUM_BEACON_HOST"
