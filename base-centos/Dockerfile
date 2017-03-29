FROM centos:centos6

MAINTAINER Mark Prichard (mark.prichard@appdynamics.com)

# Add appdynamics user and set permissions
RUN groupadd -r -g 2002 appdynamics \
    && useradd --create-home --gid appdynamics -u 2001 appdynamics \
    && echo 'appdynamics:appdynamics' | chpasswd

# Install packages
RUN yum -y --setopt=tsflags=nodocs update \
    && yum -y --setopt=tsflags=nodocs install \
        libaio-devel \
        wget \
        unzip \
        tar \
        expect \
        openssh-server \
        openssh-clients \
    && chkconfig sshd on \
    && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie	" http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm -O jdk-linux-x64.rpm \
    && rpm -Uvh jdk-linux-x64.rpm \
    && rm jdk-linux-x64.rpm \
    && yum clean all

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
