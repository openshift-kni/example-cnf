FROM quay.io/centos/centos:8

# Install prerequisite packages
RUN yum install -y wget numactl numactl-devel make cmake git wget gcc gcc-c++ kernel-headers glibc-devel net-tools \
        glibc-headers pciutils nfs-utils perf unzip xorg-x11-xauth yum-utils python36  iproute zlib-devel binutils \
        tcpdump vim && yum clean all

RUN mkdir -p /opt/trex && cd /opt/trex && git clone --branch v2.85 https://github.com/cisco-system-traffic-generator/trex-core.git

RUN cd /opt/trex/trex-core/linux_dpdk && ./b configure --no-mlx --no-bxnt --new-memory && cp dpdk_config.h /opt/trex/trex-core/src/ && ./b build

RUN cd /opt && git clone https://github.com/atheurer/trafficgen
RUN pip3 install kubernetes

ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
WORKDIR /opt/trex/trex-core/scripts
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"
COPY scripts /usr/local/bin/
