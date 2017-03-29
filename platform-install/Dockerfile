FROM appdynamics/base-centos

MAINTAINER Mark Prichard (mark.prichard@appdynamics.com)

WORKDIR /install

# Controller installation and response file
COPY controller_64bit_linux.sh /install/
COPY controller.varfile /install/

# EUEM installation and response files
COPY euem-64bit-linux.sh /install/

COPY eum.varfile /install/
COPY .bash_profile /home/appdynamics/

COPY setup-embedded-events-service.sh /install/

COPY setup-clustered-events-service.sh /install/

COPY setup-ssh.sh /install/

# AppDynamics Platform install/start/stop scripts
COPY install-appdynamics.sh /install/

COPY start-appdynamics.sh /install/
COPY stop-appdynamics.sh /install/

# AppDynamics License File
COPY license.lic /install/


RUN chmod 774 /install/controller_64bit_linux.sh \
    && chmod 774 /install/euem-64bit-linux.sh \
    && chmod 774 /install/setup-embedded-events-service.sh \
    && chmod 774 /install/setup-clustered-events-service.sh \
    && chmod 774 /install/setup-ssh.sh \
    && chmod 774 /install/install-appdynamics.sh \
    && chmod 774 /install/start-appdynamics.sh \
    && chmod 774 /install/stop-appdynamics.sh \
    && chown -R appdynamics:appdynamics /install

# Install AppDynamics Platform and exit - for manual install/upgrade use 'docker run ... controller-install bash'
CMD ["/install/install-appdynamics.sh"]
