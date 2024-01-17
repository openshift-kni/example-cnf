FROM docker.io/library/golang:1.21 as build

WORKDIR /scripts
COPY scripts/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

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

# Copy scripts
COPY scripts /usr/local/bin
COPY --from=build /scripts/webserver /usr/local/bin/

# Update permissions
RUN chmod +x /usr/local/bin/webserver
RUN chmod +x /usr/local/bin/entrypoint.sh

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
