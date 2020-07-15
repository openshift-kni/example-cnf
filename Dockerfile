FROM centos:7

# Install prerequisite packages
RUN yum update -y && yum clean all
RUN yum install -y wget numactl numactl-devel make cmake git wget gcc gcc-c++ kernel-headers glibc-devel \
        glibc-headers pciutils nfs-utils perf unzip xorg-x11-xauth yum-utils python3 python iproute && \
    yum clean all

RUN wget https://trex-tgn.cisco.com/trex/release/v2.75.tar.gz --no-check-certificate && \
    tar zxvf v2.75.tar.gz

RUN git clone https://github.com/atheurer/trafficgen

RUN pip3 install pyyaml

ENV TREX_DIR="/v2.75"
ENV TRAFFICGEN_DIR="/trafficgen"

COPY trex-standalone /trex-standalone
COPY scripts /usr/local/bin/
