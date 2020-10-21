FROM registry.access.redhat.com/ubi8/python-36:latest
USER root
RUN yum install -y nc && yum clean all
RUN mkdir -p /opt/trex && cd /opt/trex && git clone https://github.com/cisco-system-traffic-generator/trex-core.git
RUN cd /opt && git clone https://github.com/atheurer/trafficgen
RUN pip3 install pyyaml kubernetes ansible
ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"
COPY scripts /usr/local/bin/
COPY pyfiles /opt/pyfiles/
ENTRYPOINT ["trex-wrapper"]
