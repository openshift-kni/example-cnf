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

# Install Go binary
ARG GO_VERSION=go1.21.6
ADD https://go.dev/dl/$GO_VERSION.linux-amd64.tar.gz /usr/local
RUN tar -C /usr/local -xzf /usr/local/$GO_VERSION.linux-amd64.tar.gz
RUN rm /usr/local/$GO_VERSION.linux-amd64.tar.gz
ENV PATH="$PATH:/usr/local/go/bin"

# Copy scripts
COPY scripts /usr/local/bin

# Update permissions
RUN chmod +x /usr/local/bin/webserver.go
RUN chmod +x /usr/local/bin/entrypoint.sh

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
