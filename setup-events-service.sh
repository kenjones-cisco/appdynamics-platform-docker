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

SELECT_QUERY_LOCAL_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.controller.key';"
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')

SELECT_QUERY_SERVER_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.controller.key';"
ANALYTICS_SERVER_STORE_KEY=$(execMySQL "$SELECT_QUERY_SERVER_KEY" | awk '{print $1}')

UPDATE_QUERY_SERVER_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_LOCAL_STORE_KEY' WHERE name='appdynamics.analytics.server.store.controller.key';"
execMySQL "$UPDATE_QUERY_SERVER_KEY"

UPDATE_EUM_ES_HOST="UPDATE controller.global_configuration_cluster SET value='http://localhost:9080' WHERE name ='eum.es.host';"
execMySQL "$UPDATE_EUM_ES_HOST"

echo "appdynamics.analytics.local.store.controller.key: $ANALYTICS_LOCAL_STORE_KEY" 
echo "appdynamics.analytics.server.store.controller.key: $ANALYTICS_LOCAL_STORE_KEY" 
echo "eum.es.host: http://localhost:9080"

export EUM_KEY_PROPERTY=$(grep "ad.accountmanager.key.eum=" $CONTROLLER_HOME/events_service/conf/events-service-api-store.properties)
export EUM_KEY=${EUM_KEY_PROPERTY#ad.accountmanager.key.eum=}
echo "ad.accountmanager.key.eum: $EUM_KEY"

echo "eventsService.APIKey=$EUM_KEY" >> /install/eum.varfile.1
