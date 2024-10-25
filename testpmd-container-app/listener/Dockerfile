FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-39:latest

LABEL name="NFV Example Listener Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.11" \
      release="v0.2.11" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

# Install Kubernetes
USER root
RUN pip3 install kubernetes

# Create custom user to avoid using root account
RUN useradd example-cnf -u 56560

# This is to be able to manage some files that belong to root account
RUN usermod -a -G root example-cnf

# Create some support folders that will be needed during execution
RUN mkdir -p /var/log/testpmd
RUN chmod 750 /var/log/testpmd
RUN chown example-cnf /var/log/testpmd

# Copy scripts
COPY --chmod=550 scripts /usr/local/bin
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/webserver

# Move to the custom user
USER example-cnf

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/testpmd-wrapper"]
