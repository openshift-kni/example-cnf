FROM centos:latest AS builder

# Install prerequisite packages
RUN yum update -y && yum clean all
RUN yum install -y wget numactl numactl-devel make cmake git wget gcc gcc-c++ kernel-headers glibc-devel net-tools \
        glibc-headers pciutils nfs-utils perf unzip xorg-x11-xauth yum-utils python36  iproute zlib-devel binutils && \
    yum clean all

RUN mkdir -p /opt/trex && cd /opt/trex && git clone https://github.com/cisco-system-traffic-generator/trex-core.git

COPY v3-bus-pci-fix-VF-bus-error-for-memory-access.diff /v3-bus-pci-fix-VF-bus-error-for-memory-access.diff
RUN cd /opt/trex/trex-core && git apply /v3-bus-pci-fix-VF-bus-error-for-memory-access.diff
RUN cd /opt/trex/trex-core/linux_dpdk && ./b configure --no-mlx --no-bxnt && ./b build


FROM centos:latest
RUN yum update -y && yum clean all
RUN yum install -y wget git net-tools pciutils perf unzip yum-utils python36 iproute && \
    yum clean all
RUN cd /opt && git clone https://github.com/atheurer/trafficgen
RUN pip3 install pyyaml kubernetes
COPY --from=builder /opt /opt
ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"
COPY scripts /usr/local/bin/
