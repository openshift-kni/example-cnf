FROM registry.redhat.io/openshift4/dpdk-base-rhel8:v4.6.3-8

MAINTAINER skramaja@redhat.com

LABEL name="NFV Example CNF Application" \
      maintainer="skramaja@redhat.com" \
      vendor="fredco" \
      version="v0.2.1" \
      release="v0.2.1" \
      summary="An example CNF for platform valiation" \
      description="An example CNF for platform valiation"

COPY licenses /licenses

USER root
RUN yum -y update-minimal --disablerepo "*" --enablerepo rhel-8-for-x86_64-baseos-rpms \
        --enablerepo rhel-8-for-x86_64-appstream-rpms --setopt=tsflags=nodocs \
        --security --sec-severity=Important --sec-severity=Critical

USER default
