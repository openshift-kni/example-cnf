FROM registry.redhat.io/openshift4/dpdk-base-rhel8:v4.6.3-8

MAINTAINER telcoci@redhat.com

LABEL name="NFV Example CNF Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.5" \
      release="v0.2.5" \
      summary="An example CNF for platform valiation" \
      description="An example CNF for platform valiation"

COPY licenses /licenses

USER root

# it's not working and should not be needed eventually
#RUN yum -y update-minimal --disablerepo "*" --enablerepo rhel-8-for-x86_64-baseos-rpms \
#        --enablerepo rhel-8-for-x86_64-appstream-rpms --setopt=tsflags=nodocs \
#        --security --sec-severity=Important --sec-severity=Critical

# Dependencies for lifecycle webserver
RUN yum install -y python3 pip
RUN pip3 install Flask waitress

# Copy scripts
COPY scripts /usr/local/bin

# Update permissions
RUN chmod +x /usr/local/bin/webserver
RUN chmod +x /usr/local/bin/entrypoint.sh

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
