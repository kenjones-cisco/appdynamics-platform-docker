#!/bin/bash

ssh-keygen -t rsa -f /home/appdynamics/.ssh/id_rsa_appd -N ''

nodes=( "$@" )

for i in "${nodes[@]}"
do
  /install/setup-ssh.sh "$i" appdynamics appdynamics
done

echo "Starting Platform Admin service..."
/appdynamics/Controller/platform_admin/bin/platform-admin.sh start-platform-admin
echo

echo "Creating clustered Events Service..."
/appdynamics/Controller/platform_admin/bin/platform-admin.sh install-events-service --ssh-key-file /home/appdynamics/.ssh/id_rsa_appd --remote-user appdynamics --installation-dir /home/appdynamics --hosts "$@" --profile dev
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

SELECT_QUERY_LOCAL_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.url';"
SELECT_QUERY_LOCAL_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.local.store.controller.key';"
SELECT_QUERY_SERVER_URL="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.url';"
SELECT_QUERY_SERVER_KEY="SELECT value FROM controller.global_configuration_cluster WHERE name='appdynamics.analytics.server.store.controller.key';"

# Get the existing values for local/server url/key
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')
ANALYTICS_SERVER_STORE_URL=$(execMySQL "$SELECT_QUERY_SERVER_URL" | awk '{print $1}')
ANALYTICS_SERVER_STORE_KEY=$(execMySQL "$SELECT_QUERY_SERVER_KEY" | awk '{print $1}')

UPDATE_QUERY_LOCAL_KEY="UPDATE controller.global_configuration_cluster SET value='$ANALYTICS_SERVER_STORE_KEY' WHERE name='appdynamics.analytics.local.store.controller.key';"
UPDATE_QUERY_LOCAL_URL="UPDATE controller.global_configuration_cluster SET value='http://nginx:9080' WHERE name='appdynamics.analytics.local.store.url';"
UPDATE_QUERY_SERVER_URL="UPDATE controller.global_configuration_cluster SET value='http://nginx:9080' WHERE name='appdynamics.analytics.server.store.url';"

# Set the local key/url to match the server store values
execMySQL "$UPDATE_QUERY_LOCAL_KEY"

# Set local/server store to use proxy url
execMySQL "$UPDATE_QUERY_LOCAL_URL"
execMySQL "$UPDATE_QUERY_SERVER_URL"

# Retrieve the updated values
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')
ANALYTICS_LOCAL_STORE_KEY=$(execMySQL "$SELECT_QUERY_LOCAL_KEY" | awk '{print $1}')
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

echo "eventsService.host=nginx" >> /install/eum.varfile.1
echo "eventsService.APIKey=$EUM_KEY" >> /install/eum.varfile.1
