FROM docker.io/library/golang:1.21 as build

WORKDIR /scripts
COPY scripts/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-311:latest

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

# Copy scripts
COPY scripts /usr/local/bin/
COPY --from=build /scripts/webserver /usr/local/bin/

# Update permissions
RUN chmod +x /usr/local/bin/webserver

COPY pyfiles /opt/pyfiles/
ENTRYPOINT ["trex-wrapper"]
