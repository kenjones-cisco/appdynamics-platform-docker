#!/bin/bash

read -rp 'Enter Events Service Controller API Key: ' API_KEY
read -rp 'Enter Events Service EUM API Key: ' EUM_KEY

PORT=3388
USER=controller
PASS=controller
DB=controller

CONTROLLER_HOME="/appdynamics/Controller"
MY_SQL_HOME=$CONTROLLER_HOME/db/bin

function execMySQL {
	echo "$1" | ${MY_SQL_HOME}/mysql --port=$PORT -u $USER --password=$PASS --database=$DB | tail -1
}

# Configure user-supplied Events Service API key values
ANALYTICS_LOCAL_STORE_KEY=${API_KEY}
ANALYTICS_SERVER_STORE_KEY=${API_KEY}

UPDATE_QUERY_LOCAL_URL="UPDATE controller.global_configuration_cluster SET value='http://localhost:9080' WHERE name='appdynamics.analytics.local.store.url';"
UPDATE_QUERY_LOCAL_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_SERVER_STORE_KEY' WHERE name='appdynamics.analytics.local.store.controller.key';"
UPDATE_QUERY_SERVER_URL="UPDATE controller.global_configuration_cluster SET value='http://localhost:9080' WHERE name='appdynamics.analytics.server.store.url';" 
UPDATE_QUERY_SERVER_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_LOCAL_STORE_KEY' WHERE name='appdynamics.analytics.server.store.controller.key';"

# Update local/server store key/url values
execMySQL "$UPDATE_QUERY_LOCAL_URL"
execMySQL "$UPDATE_QUERY_LOCAL_KEY"
execMySQL "$UPDATE_QUERY_SERVER_URL"
execMySQL "$UPDATE_QUERY_SERVER_KEY"

SELECT_QUERY_LOCAL_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.url';"
SELECT_QUERY_LOCAL_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.controller.key';"
SELECT_QUERY_SERVER_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.url';"
SELECT_QUERY_SERVER_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.controller.key';"

# Confirm updated local/server store key/url values
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')
ANALYTICS_SERVER_STORE_URL=$(execMySQL "$SELECT_QUERY_SERVER_URL" | awk '{print $1}')
ANALYTICS_SERVER_STORE_KEY=$(execMySQL "$SELECT_QUERY_SERVER_KEY" | awk '{print $1}')

echo "appdynamics.analytics.local.store.url: $ANALYTICS_LOCAL_STORE_URL"
echo "appdynamics.analytics.local.store.controller.key: $ANALYTICS_LOCAL_STORE_KEY"
echo "appdynamics.analytics.server.store.url: $ANALYTICS_SERVER_STORE_URL"
echo "appdynamics.analytics.server.store.controller.key: $ANALYTICS_SERVER_STORE_KEY"

echo "eventsService.host=localhost" >> /install/eum.varfile.1
echo "eventsService.APIKey=${EUM_KEY}" >> /install/eum.varfile.1
