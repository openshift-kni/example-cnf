FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
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
COPY --chmod=550 scripts/entrypoint.sh /usr/local/bin/
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
