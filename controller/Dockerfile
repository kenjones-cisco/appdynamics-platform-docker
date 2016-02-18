FROM appdynamics/base-centos

MAINTAINER Mark Prichard (mark.prichard@appdynamics.com)

RUN mkdir -p /install

# Controller installation and response file
ADD /controller_64bit_linux.sh /install/
RUN chmod 774 /install/controller_64bit_linux.sh
ADD /controller.varfile /install/

ADD /setup-local-events-service.sh /install/
RUN chmod 774 /install/setup-local-events-service.sh

# AppDynamics License File - Uncomment to add to build
ADD /license.lic /install/

# AppDynamics Platform install/start/stop scripts
ADD /install-controller.sh /install/
RUN chmod 774 /install/install-controller.sh

ADD /start-appdynamics.sh /install/
RUN chmod 774 /install/start-appdynamics.sh

ADD /stop-appdynamics.sh /install/
RUN chmod 774 /install/stop-appdynamics.sh

RUN chown -R appdynamics:appdynamics /install

RUN /install/install-controller.sh

CMD /install/start-appdynamics.sh

EXPOSE 8090
