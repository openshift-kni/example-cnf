## Image to build webserver
FROM registry.access.redhat.com/ubi9/go-toolset:1.24 as build

WORKDIR /opt/app-root/src
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

## grout image
FROM quay.io/rh-nfv-int/ubi9-base-grout:v0.0.1

LABEL name="NFV Example CNF Grout Application" \
      maintainer="telcoci" \
      vendor="fredco" \
      version="v0.2.5" \
      release="v0.2.5" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

ENV GROUT_VER v0.14.3
ENV GROUT_RPM https://github.com/DPDK/grout/releases/download/${GROUT_VER}/grout.x86_64.rpm

# check latest release from https://github.com/DPDK/grout/releases
RUN dnf -y install ${GROUT_RPM}

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
RUN mkdir -p /var/log/grout
RUN chmod 750 /var/log/grout
RUN chown example-cnf /var/log/grout

# Copy scripts
COPY --chmod=550 --from=build /opt/app-root/src/webserver /usr/local/bin/webserver
COPY --chmod=550 scripts/grout-wrapper /usr/local/bin/example-cnf/grout-wrapper
COPY --chmod=550 scripts/retrieve-grout-ip-addresses /usr/local/bin/example-cnf/retrieve-grout-ip-addresses

# Move to the custom user
USER example-cnf

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/example-cnf/grout-wrapper"]
