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
SELECT_QUERY_LOCAL_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.url';"
SELECT_QUERY_SERVER_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.url';"
SELECT_QUERY_SERVER_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.controller.key';"

# Retrieve existing local store key
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')

UPDATE_QUERY_SERVER_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_LOCAL_STORE_KEY' WHERE name='appdynamics.analytics.server.store.controller.key';"

# Update server store to use local store key
execMySQL "$UPDATE_QUERY_SERVER_KEY"

# Retrieve updated local/server url/key values
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')
ANALYTICS_SERVER_STORE_URL=$(execMySQL "$SELECT_QUERY_SERVER_URL" | awk '{print $1}')
ANALYTICS_SERVER_STORE_KEY=$(execMySQL "$SELECT_QUERY_SERVER_KEY" | awk '{print $1}')

echo "appdynamics.analytics.local.store.url: $ANALYTICS_LOCAL_STORE_URL"
echo "appdynamics.analytics.local.store.controller.key: $ANALYTICS_LOCAL_STORE_KEY"
echo "appdynamics.analytics.server.store.url: $ANALYTICS_SERVER_STORE_URL"
echo "appdynamics.analytics.server.store.controller.key: $ANALYTICS_SERVER_STORE_KEY"

# Set EUM API key and proxy url
export EUM_KEY_PROPERTY
EUM_KEY_PROPERTY=$(grep "ad.accountmanager.key.eum=" $CONTROLLER_HOME/events_service/conf/events-service-api-store.properties)
export EUM_KEY
EUM_KEY=${EUM_KEY_PROPERTY#ad.accountmanager.key.eum=}
echo "ad.accountmanager.key.eum: $EUM_KEY"

echo "eventsService.host=localhost" >> /install/eum.varfile.1
echo "eventsService.APIKey=$EUM_KEY" >> /install/eum.varfile.1
