# AppDynamics Platform Docker Containers
Docker containers for installing and running the AppDynamics Controller with EUM Server and Analytics support on Centos or Ubuntu base images. These containers allow you to manage an AppDynamics Platform install using Docker, with persistent data storage for the AppDynamics installation and database.

## Please Note
This project uses a single-host installation for the AppDynamics Controller and End User Monitoring, with either the embedded or clustered Events Service.  This is suitable for small, demonstration installations only: for production deployments please see the [product documentation](https://docs.appdynamics.com/display/PRO41/Install+the+Events+Service).

The master branch has been tested with the current (4.2) version of the AppDynamics Platform.  There are some minor differences between 4.1 and 4.2, so if you wish to build containers that work with version 4.1, please pull the 4.1 branch of this repo and use that.

## Quick Summary
1. (Initialize data volume) `docker run --name platform-data appdynamics/platform-data`
2. (Install AppDynamics) `docker run --rm -it --name platform-install -h controller --volumes-from platform-data  appdynamics/platform-install`
3. (Add license file) `docker run --rm -it --volumes-from platform-data -v $(pwd)/:/license appdynamics/platform-install bash -c "cp /license/license.lic /appdynamics/Controller"`
4. (Start AppDynamics) `docker run -d --name platform -h controller -p 8090:8090 -p 7001:7001 -p 9080:9080 --volumes-from platform-data appdynamics/platform start-appdynamics`
5. (Stop AppDynamics) `docker exec platform stop-appdynamics`
6. (Restart AppDynamics) `docker exec platform start-appdynamics`

## Base Images
These contain the base OS and any required packages.  To change the OS version or add a package, rebuild the base image, tag it appropriately and update the FROM directive in the platform-install and platform Dockerfiles.  The following base images are provided as examples only; for a list of supported environments, please see the [product documentation](https://docs.appdynamics.com/display/PRO42/Supported+Environments+and+Versions).

1. base-centos (base image: Centos 6)
2. base-ubuntu (base image: Ubuntu 12.04)

To build: e.g. `cd base-centos; docker build -t appdynamics/base-centos .`

## Initialize the Data Volume
Creates a data volume with an empty /appdynamics directory, owned by user appdynamics:appdynamics.  This should be run to initialize the data volume before running platform-install to install the AppDynamics Platform. In the following example, the container is called platform-data and this is used with the docker `--volumes-from` flag to identify the data volume when running the platform-install and platform containers. The container exports the data volume, prints a confirmation message and exits. Note that deleting the container will delete the data volume.

- `docker run --name platform-data appdynamics/platform-data`

## Install the AppDynamics Platform
This contains the scripts and binaries required to install the AppDynamics Platform (Controller, EUEM and Analytics) on a mounted docker volume.  This volume should be initialized first using the platform-data container, before platform-install is run to complete installation.  Normally, you would run `platform-install` once to lay down the /appdynamics install directory, and then use `platform` to start and stop the AppDynamics Controller and EUM Server/Events Service. This container can also be used to upgrade an existing installation or perform a manual install by running it with `bash` as the container entrypoint.

- (normal install) `docker run --rm -it --name platform -h controller --volumes-from platform-data  appdynamics/platform-install`
- (manual install/upgrade) `docker run --rm -it --name platform -h controller --volumes-from platform-data  appdynamics/platform-install bash`

## Add the License File
You can add the license file either at build time or run time.
#### Run time
Once the platform-install container has started, use `docker run -v` to add your AppDynamics license file. The following command can be used to inject the license file - this needs to run in a separate terminal, while the AppDynamics Controller installation is running:
- `docker run --rm -it --volumes-from platform-data -v $(pwd)/:/license appdynamics/platform-install bash -c "cp /license/license.lic /appdynamics/Controller"`

#### Build time
To add the license file at build time, uncomment the following line in the `platform-install` Dockerfile:
- `ADD /license.lic /install/`

The `build.sh` script will copy the license file (if one exists) from the project root to the `platform-install` directory. As part of the install, the license file will be copied to the `/appdynamics/Controller/` folder.

## Run the AppDynamics Controller and EUM Server

This contains scripts to run the AppDynamics Platform. It should be used with a mounted docker volume (see `platfrom-data`) containing the /appdynamics install directory created with `platform-install`.  Note that the hostname (set with the -h flag) should match that used for the platform installation.
- `docker run -d --name platform -h controller -p 8090:8090 -p 7001:7001 -p 9080:9080 --volumes-from platform-data appdynamics/platform start-appdynamics`
- `docker exec platform stop-appdynamics`
- `docker exec platform start-appdynamics`

## Building the containers
The base images can be build manually from their respective directories.  The `platform`, `platfrom-data` and `platfrom-install` containers should be built using the `build.sh` script. The build requires the following AppDynamics install files, which can be supplied from the commandline or downloaded from the [AppDynamics Download Site](https://download.appdynamics.com/).

1. AppDynamics Ccontroller installer (64-bit Linux)
2. AppDynamics EUM Server installer (64-bit Linux)

To build the containers, run `build.sh` with one of the following options:

1. Run `build.sh` without commandline args to be prompted (with autocomplete) for the controller and EUM installer paths
2. Run `build.sh -c <path_to_controller_installer> -e <path_to_euem_installer>` to supply installer paths
3. Run `build.sh --download` to download from `https://download.appdynamics.com` (portal login required)

## Connecting to the Controller
You can change any of the ports used in the silent installer response varfiles:
- [controller.varfile](https://github.com/Appdynamics/appdynamics-platform-docker/blob/master/controller.varfile)
- [eum.varfile](https://github.com/Appdynamics/appdynamics-platform-docker/blob/master/eum.varfile)

Note: you will need to rebuild the container images for these changes to take effect.  See the [product documentation](https://docs.appdynamics.com/display/PRO41/Install+the+Controller#InstalltheController-installeroptionsInstallationConfigurationSettings) for more information about the silent installer settings.

You can remap any ports used by the AppDynamics Platform to different ports on your lcoal system, using the `docker run -p` option.  For example `-p 80:8090` will map the Controller server port 8090 to your default HTTP port 80.

If you are using [boot2docker](http://boot2docker.io/) or [docker-machine](https://docs.docker.com/machine/) to run docker on OSX/Windows, you should use the following commands to determine the Docker host's IP address:

- boot2docker: `boot2docker ip`
- docker-machine: `docker-machine ip default`

You can use the following VirtualBox command to map port 8090 on the docker container to your localhost interface

`VBoxManage controlvm boot2docker-vm natpf1 "8090-8090,tcp,127.0.0.1,8090,,8090"`

### Default logins

- Controller login: user1/welcome
- Root user login: welcome

## Configuring the Events Service

During installation of the AppDynamics Platform, you can choose whether you wish to use the embedded version of the Events Service that comes bundled with the Controller, or a clustered Events Service, with cluster nodes accessed via an [nginx](https://hub.docker.com/_/nginx/) reverse proxy.  The latter architecture requires additional docker containers to run the Events Service nodes and the reverse proxy.

### Using the Embedded Events Service

If you select the Embedded Events Service during installation, then the platform-install container with automatically configure the Analytics and EUM services to use the embedded Events Service that ships with the Controller.

### Using the Clustered Events Service (auto configuration)

If you select the clustered Events Service (auto configuration) option, then you will be prompted to start the containers for the Events Service nodes and the nginx reverse proxy server that will front the cluster. These can be started easily using [docker-compose](https://www.docker.com/docker-compose): you will find all the files in the `es-cluster` folder and there are details of how to configure and start the Events Service containers below.

### Using the Clustered Events Service (auto configuration)

If you select the clustered Events Service (manual configuration) option, then you can choose where the Events Service nodes should run.  You will be prompted for the list of nodes (you can use hostnames or IP addresses) that the platform admin utility will attempt to use for the Events Service.

Make sure that you have the nginx proxy set up to reverse proxy to the cluster by editing the [nginx.conf file](https://github.com/Appdynamics/appdynamics-platform-docker/blob/master/es-cluster/nginx.conf). You may need to use `--link nginx:nginx` when running the platform-install and platform containers to ensure that the Controller is able to reach the proxy server.

You also need to ensure that the Events Service nodes are reachable from every member of the cluster: docker does not allow circular `--link` references, so if you are running the nodes as docker containers and not using [docker-compose](https://www.docker.com/docker-compose), you may need to pass the IP addresses of the nodes when installing the platform. The following command is an easy way to obtain the IP address of a running comtainer:

- `docker inspect --format '{{ .NetworkSettings.IPAddress }}' node1`

### Starting the Events Service Cluster

The `appdynamics/es-cluster-node` image uses a Centos 6 base image and has the appdynamics user pre-configured.  Change directory to the `es-cluster` folder and follow the following steps to build the base image and then start a 3-node cluster with an nginx reverse-proxy server, as described in the docs: [Load Balance Events Service Traffic](https://docs.appdynamics.com/display/PRO42/Load+Balance+Events+Service+Traffic):

- `docker build -t appdynamics/es-cluster-node .`
- `docker-compose -f nodes.yml up -d`
- `docker-compose -f proxy.yml up -d`

If you are running the project on EC2, you can run the cluster nodes/proxy using docker-compose via the [EC2 Container Service](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html) or by using the following commands:

- `docker run -d --name node1 -h node1 appdynamics/es-cluster-node`
- `docker run -d --name node2 -h node2 appdynamics/es-cluster-node`
- `docker run -d --name node3 -h node3 appdynamics/es-cluster-node`
- `docker run -d --name nginx -h nginx -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf:ro --link node1:node1 --link node2:node2 --link node3:node3 nginx`

### Configuring Password-less SSH

The AppDynamics Platform Admin application requires that all Events Service nodes be configured for password-less SSH login as described in the docs: [Configure SSH Passwordless Login](https://docs.appdynamics.com/display/PRO42/Install+the+Events+Service+on+Linux#InstalltheEventsServiceonLinux-settingupenvironmentconfigloginConfigureSSHPasswordlessLogin). This project includes a Tcl/Expect utlity (setup-ssh.sh) which will configure password-less SSH between the Controller and the Events Service nodes, if you choose the clustered Events Service option.

### Running the Clustered Event Service

If you select the clustered Events Service option, the platform-install container will start the Platform Admin application to configure and check the health of the Events Service Cluster. The Platform Admin application uses the `--profile dev` flag to by-pass the strict memory and disk space requirements for an Events Ervice node: please remember that this is NOT recommended for production use.

