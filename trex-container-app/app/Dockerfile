FROM registry.access.redhat.com/ubi8/python-311:latest

ENV TREX_VER v2.85
ENV TREX_REPO https://github.com/cisco-system-traffic-generator/trex-core.git
ENV TRAFFICGEN_REPO https://github.com/atheurer/trafficgen

USER root

RUN yum install -y nc && yum clean all
RUN mkdir -p /opt/trex && cd /opt/trex && git clone --branch ${TREX_VER}  ${TREX_REPO}
RUN cd /opt && git clone  ${TRAFFICGEN_REPO}
RUN pip3 install pyyaml kubernetes

# Install Go binary
ARG GO_VERSION=go1.21.6
ADD https://go.dev/dl/$GO_VERSION.linux-amd64.tar.gz /usr/local
RUN tar -C /usr/local -xzf /usr/local/$GO_VERSION.linux-amd64.tar.gz
RUN rm /usr/local/$GO_VERSION.linux-amd64.tar.gz
ENV PATH="$PATH:/usr/local/go/bin"

ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"

COPY scripts /usr/local/bin/
RUN chmod +x /usr/local/bin/webserver.go
COPY pyfiles /opt/pyfiles/
ENTRYPOINT ["trex-wrapper"]
