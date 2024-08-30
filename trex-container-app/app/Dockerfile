FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-311:latest

LABEL name="NFV Example TRexApp Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.11" \
      release="v0.2.11" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

ENV TREX_VER v2.85
ENV TREX_REPO https://github.com/cisco-system-traffic-generator/trex-core.git
ENV TRAFFICGEN_REPO https://github.com/atheurer/trafficgen

USER root

RUN yum install -y nc && yum clean all
RUN mkdir -p /opt/trex && cd /opt/trex && git clone --branch ${TREX_VER}  ${TREX_REPO}
RUN cd /opt && git clone  ${TRAFFICGEN_REPO}
RUN pip3 install pyyaml kubernetes

ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"

# Create custom user to avoid using root account
RUN useradd example-cnf

# This is to be able to manage some files that belong to root account
RUN usermod -a -G root example-cnf

# Create some support folders that will be needed during execution
RUN mkdir -p /var/log/trex
RUN chmod 750 /var/log/trex
RUN chown example-cnf:example-cnf /var/log/trex

# Copy scripts
COPY --chmod=550 scripts /usr/local/bin/
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/webserver
COPY --chmod=550 pyfiles /opt/pyfiles/

# Move to the custom user
USER example-cnf

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/trex-wrapper"]
