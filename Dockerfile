FROM centos:7
LABEL maintainer="Nick Booher <njbooher@iastate.edu>"

ENV \
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/ \
    PATH=/opt/app-root/:$PATH \
    # where bin directories are
    CATALINA_HOME=/usr/share/tomcat \
    # where webapps are deployed
    CATALINA_BASE=/opt/app-root/tomcatbase \
    CONTEXT_PATH=ROOT \
    JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    GIT_COMMITTER_NAME=asdf \
    GIT_COMMITTER_EMAIL=asdf@example.com


# package installation
RUN yum install -y centos-release-scl && \
    yum install -y autoconf automake bzip2 gcc-c++ gd-devel gdb git libcurl-devel libxml2-devel libxslt-devel lsof make mariadb-devel mariadb-libs openssl-devel patch postgresql-devel procps-ng sqlite-devel unzip wget which zlib-devel && \
    yum install -y rh-nodejs10-npm && \
    yum install -y rh-python36 rh-python36-python-devel rh-python36-python-setuptools rh-python36-python-pip && \
    yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel tomcat

RUN source scl_source enable rh-nodejs10 && \
    npm i -g yarn   

RUN curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/blat/blat" -o /usr/local/bin/blat && \
 		chmod +x /usr/local/bin/blat && \
 		curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit" -o /usr/local/bin/faToTwoBit && \
 		chmod +x /usr/local/bin/faToTwoBit

# make tomcat base
RUN mkdir -p ${CATALINA_BASE} && cd ${CATALINA_BASE} && mkdir bin && mkdir lib && mkdir logs && mkdir temp && mkdir webapps && mkdir work
RUN cp -R ${CATALINA_HOME}/conf/ ${CATALINA_BASE}/

# Copy in installdeps.R to set cran mirror & handle package installs
RUN mkdir -p /opt/app-root
COPY ./build.sh /opt/app-root/src/
COPY ./docker-apollo-config.groovy /opt/app-root/src/apollo-config.groovy
COPY ./createenv.sh /opt/app-root/createenv.sh

COPY fix-permissions /usr/bin/

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/assemble /opt/app-root/
COPY ./s2i/bin/run /opt/app-root/

# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN chown -R 1001:0 ${APP_ROOT} && \
    fix-permissions ${APP_ROOT} -P

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001

RUN git clone https://github.com/GMOD/Apollo.git /tmp/src && \
    mkdir -p ${APP_ROOT}/src && \
    cd ${APP_ROOT}/src && \
    /opt/app-root/assemble

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["/opt/app-root/run"]
