FROM centos:7

# Install prerequisite packages
RUN yum update -y && yum clean all
RUN yum install -y wget numactl numactl-devel make cmake git wget gcc gcc-c++ kernel-headers glibc-devel \
        glibc-headers pciutils nfs-utils perf unzip xorg-x11-xauth yum-utils python3 python iproute zlib-devel binutils && \
    yum clean all

WORKDIR /opt
RUN git clone https://github.com/atheurer/trafficgen

RUN pip3 install pyyaml kubernetes

WORKDIR /opt/trex
RUN git clone https://github.com/cisco-system-traffic-generator/trex-core.git

WORKDIR /opt/trex/trex-core
COPY v3-bus-pci-fix-VF-bus-error-for-memory-access.diff /v3-bus-pci-fix-VF-bus-error-for-memory-access.diff
RUN git apply /v3-bus-pci-fix-VF-bus-error-for-memory-access.diff
WORKDIR /opt/trex/trex-core/linux_dpdk
RUN ./b configure --no-mlx --no-bxnt && ./b build

WORKDIR /opt/trex/trex-core/scripts

ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
ENV TREX_DIR="/opt/trex/current"
ENV TRAFFICGEN_DIR="/opt/trafficgen"

COPY scripts /usr/local/bin/
