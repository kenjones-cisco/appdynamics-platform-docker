#!/bin/bash

ssh-keygen -t rsa -f /home/appdynamics/.ssh/id_rsa_appd -N ''

nodes=( node1 node2 node3 )
for i in "${nodes[@]}"
do
  /install/setup-ssh.sh $i appdynamics appdynamics
done

echo "Starting Platform Admin service..."
/appdynamics/Controller/platform_admin/bin/platform-admin.sh start-platform-admin
echo

echo "Creating clustered Events Service..."
/appdynamics/Controller/platform_admin/bin/platform-admin.sh install-events-service --ssh-key-file /home/appdynamics/.ssh/id_rsa_appd --remote-user appdynamics --installation-dir /home/appdynamics --hosts node1 node2 node3 --profile dev
echo

echo "Checking Events Service health..."
/appdynamics/Controller/platform_admin/bin/platform-admin.sh show-events-service-health
echo

echo "Configuring Analytics and EUM to use clustered Events Service..."

PORT=3388
USER=controller
PASS=controller
DB=controller

CONTROLLER_HOME="/appdynamics/Controller"
MY_SQL_HOME=$CONTROLLER_HOME/db/bin

function execMySQL {
        echo "$1" | ${MY_SQL_HOME}/mysql --port=$PORT -u $USER --password=$PASS --database=$DB | tail -1
}

# Get the existing values for local/server url/key
SELECT_QUERY_LOCAL_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.url';"
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')

SELECT_QUERY_LOCAL_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.controller.key';"
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')

SELECT_QUERY_SERVER_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.url';"
ANALYTICS_SERVER_STORE_URL=$(execMySQL "$SELECT_QUERY_SERVER_URL" | awk '{print $1}')

SELECT_QUERY_SERVER_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.controller.key';"
ANALYTICS_SERVER_STORE_KEY=$(execMySQL "$SELECT_QUERY_SERVER_KEY" | awk '{print $1}')

# Set the local key/url to match the server store values
UPDATE_QUERY_SERVER_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_SERVER_STORE_KEY' WHERE name='appdynamics.analytics.local.store.controller.key';"
execMySQL "$UPDATE_QUERY_SERVER_KEY"

UPDATE_QUERY_SERVER_URL="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_SERVER_STORE_URL' WHERE name='appdynamics.analytics.local.store.url';"
execMySQL "$UPDATE_QUERY_SERVER_URL"

# Retrieve the updated values
SELECT_QUERY_LOCAL_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.url';"
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')

SELECT_QUERY_LOCAL_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.controller.key';"
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')

#SELECT_QUERY_EUM_ES="SELECT value FROM controller.global_configuration_cluster WHERE name='eum.es.host';"
#EUM_ES_URL=$(execMySQL "$SELECT_QUERY_EUM_ES" | awk '{print $1}')
#echo "eum.es.host: $EUM_ES_URL"

echo "appdynamics.analytics.local.store.url: $ANALYTICS_LOCAL_STORE_URL"
echo "appdynamics.analytics.local.store.controller.key: $ANALYTICS_LOCAL_STORE_KEY"
echo "appdynamics.analytics.server.store.url: $ANALYTICS_SERVER_STORE_URL"
echo "appdynamics.analytics.server.store.controller.key: $ANALYTICS_SERVER_STORE_KEY"

export EUM_KEY_PROPERTY=$(grep "ad.accountmanager.key.eum=" $CONTROLLER_HOME/events_service/conf/events-service-api-store.properties)
export EUM_KEY=${EUM_KEY_PROPERTY#ad.accountmanager.key.eum=}
echo "ad.accountmanager.key.eum: $EUM_KEY"

export ES_REMOVE_SCHEME=${ANALYTICS_SERVER_STORE_URL#http://}
export ES_REMOVE_SCHEME_AND_PORT=${ES_REMOVE_SCHEME%:9080}
echo "eventsService.host=${ES_REMOVE_SCHEME_AND_PORT}" >> /install/eum.varfile.1
echo "eventsService.APIKey=$EUM_KEY" >> /install/eum.varfile.1
