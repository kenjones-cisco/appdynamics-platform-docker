#!/bin/bash

# This script is provided for illustration purposes only.
#
# To build these Docker containers, you will need to download the following components:
# 1. An appropriate version of the Oracle Java 7 JDK
#    (http://www.oracle.com/technetwork/java/javase/downloads/index.html)
# 2. Correct versions for the AppDynamics Controller and EUM Server (64-bit Linux)
#    (https://download.appdynamics.com)

echo "Starting AppDynamics Controller"
echo "*******************************"
echo
su - appdynamics -c '/appdynamics/Controller/bin/startController.sh'

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
ANALYTICS_LOCAL_STORE_URL=$(execMySQL "$SELECT_QUERY_LOCAL_URL" | awk '{print $1}')

if [[ $ANALYTICS_LOCAL_STORE_URL == *localhost* ]]; then
  echo
  echo "Starting Embedded Events Service"
  echo "********************************"
  echo
  su - appdynamics -c '/appdynamics/Controller/bin/controller.sh start-events-service'
  sleep 10
fi

#echo
#echo "Starting EUM Server"
#echo "*******************"
#echo
su - appdynamics -c '(cd /appdynamics/EUM/eum-processor; ./bin/eum.sh start)'

echo
echo "AppDynamics Platform Started"
echo "****************************"
echo

tail -f /appdynamics/Controller/logs/server.log
