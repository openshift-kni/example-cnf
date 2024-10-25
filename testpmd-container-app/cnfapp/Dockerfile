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

# Create custom user to avoid using root account
RUN useradd example-cnf -u 56560

# This is to be able to manage some files that belong to root account
RUN usermod -a -G root example-cnf

# Allow example-cnf to use sudo permissions without asking for password
RUN echo -e "example-cnf\tALL=(ALL)\tNOPASSWD: ALL" > /etc/sudoers.d/example-cnf

# Create a folder managed by the custom user to place the scripts to launch
RUN mkdir -p /usr/local/bin/example-cnf
RUN chmod 750 /usr/local/bin/example-cnf
RUN chown example-cnf /usr/local/bin/example-cnf
RUN mkdir /usr/local/bin/example-cnf/run

# Create some support folders that will be needed during execution
RUN mkdir -p /var/log/testpmd
RUN chmod 750 /var/log/testpmd
RUN chown example-cnf /var/log/testpmd

# Copy scripts
COPY --chmod=550 --from=build2 /utils/webserver /usr/local/bin/webserver
COPY --chmod=550 --from=build /usr/local/bin/dpdk-testpmd /usr/local/bin/example-cnf/testpmd
COPY --chmod=550 scripts/testpmd-wrapper /usr/local/bin/example-cnf/testpmd-wrapper

# Move to the custom user
USER example-cnf

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/example-cnf/testpmd-wrapper"]
