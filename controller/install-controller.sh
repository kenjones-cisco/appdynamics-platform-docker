#!/bin/bash

# This script is provided for illustration purposes only.
#
# To build these Docker containers, you will need to download the following components:
# 1. An appropriate version of the Oracle Java 7 JDK
#    (http://www.oracle.com/technetwork/java/javase/downloads/index.html)
# 2. Correct versions for the AppDynamics Controller and EUM Server (64-bit Linux)
#    (https://download.appdynamics.com)

# Use container hostname for response files
sed -e "s/SERVERHOSTNAME/`cat /etc/hostname`/g" /install/controller.varfile > /install/controller.varfile.1
chown appdynamics:appdynamics /install/*.varfile.1

# Create controller install directory
export APPD_INSTALL_DIR=/appdynamics
mkdir -p $APPD_INSTALL_DIR/Controller
chown appdynamics:appdynamics $APPD_INSTALL_DIR/Controller

# Install or prompt for license file
if [ -f /install/license.lic ]; then
  cp /install/license.lic /appdynamics/Controller/
else
  exit
fi

if [ -f $APPD_INSTALL_DIR/Controller/license.lic ]; then
  chown appdynamics:appdynamics $APPD_INSTALL_DIR/Controller/license.lic
  chmod 744 $APPD_INSTALL_DIR/Controller/license.lic
else
  echo "Could not find $APPD_INSTALL_DIR/Controller/license.lic - exiting"
  exit
fi

su - appdynamics -c "cat /install/controller.varfile.1"
chown appdynamics:appdynamics /install/controller_64bit_linux.sh
chmod 774 /install/controller_64bit_linux.sh
su - appdynamics -c '/install/controller_64bit_linux.sh -q -varfile /install/controller.varfile.1'
su - appdynamics -c '/install/setup-local-events-service.sh'
su - appdynamics -c '/appdynamics/Controller/bin/stopController.sh'
