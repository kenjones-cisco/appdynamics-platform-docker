FROM ubuntu:14.04

MAINTAINER Mark Prichard (mark.prichard@appdynamics.com)

# Add appdynamics user and set permissions
RUN groupadd -r appdynamics \
    && useradd --create-home --gid appdynamics appdynamics \
    && echo 'appdynamics:appdynamics' | chpasswd

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
        echo '#!/bin/sh'; \
        echo 'set -e'; \
        echo; \
        echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
    } > /usr/local/bin/docker-java-home \
    && chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

ENV LANG C.UTF-8
ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python-software-properties \
        software-properties-common \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 \
    && add-apt-repository -y ppa:webupd8team/java \
    && echo 'oracle-java7-installer shared/accepted-oracle-license-v1-1 select true' | /usr/bin/debconf-set-selections \
    && apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        curl \
        expect \
        libaio1 \
        openssh-server \
        openssh-client \
        oracle-java7-installer \
    && rm -rf /var/lib/apt/lists/* \
    && echo "appdynamics hard nofile 65536" >  /etc/security/limits.d/appdynamics \
    && echo "appdynamics soft nofile 65536" >> /etc/security/limits.d/appdynamics \
    && [ "$JAVA_HOME" = "$(docker-java-home)" ]

ENV PATH $PATH:$JAVA_HOME/bin
