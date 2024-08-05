## Build image
FROM quay.io/rh-nfv-int/dpdk-23.11:v0.0.1 as build

## Image to build webserver
FROM docker.io/library/golang:1.21 as build2

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

## testpmd image
FROM quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1

LABEL name="NFV Example CNF Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.11" \
      release="v0.2.11" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

# Copy scripts
COPY --chmod=550 --from=build2 /utils/webserver /usr/local/bin/
COPY --chmod=550 --from=build /usr/local/bin/dpdk-testpmd /usr/local/bin/testpmd
COPY --chmod=550 scripts/testpmd-run /usr/local/bin/testpmd-run

USER 65532:65532

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/testpmd-run"]
