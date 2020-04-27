FROM centos/s2i-base-centos7
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
    CATALINA_BASE=/usr/share/tomcat \
    CONTEXT_PATH=ROOT \
    JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk


# package installation
RUN yum -y install epel-release && \
        yum -y install java-1.8.0-openjdk tomcat

RUN npm i -g yarn

RUN curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/blat/blat" -o /usr/local/bin/blat && \
 		chmod +x /usr/local/bin/blat && \
 		curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit" -o /usr/local/bin/faToTwoBit && \
 		chmod +x /usr/local/bin/faToTwoBit


# Copy in installdeps.R to set cran mirror & handle package installs
COPY ./build.sh /opt/app-root/src

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN chown -R 1001:0 ${APP_ROOT} && \
    fix-permissions ${APP_ROOT} -P

# Copy the passwd template for nss_wrapper
COPY passwd.template /tmp/passwd.template

USER 1001

EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["/usr/libexec/s2i/run"]
