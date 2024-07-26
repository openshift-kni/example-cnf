FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

# Use ubi8/ubi as image
FROM registry.access.redhat.com/ubi8/ubi:latest

ENV TREX_VER v2.85
ENV TREX_REPO https://github.com/cisco-system-traffic-generator/trex-core.git
ENV TRAFFICGEN_REPO https://github.com/atheurer/trafficgen

# Install prerequisite packages from UBI repos
RUN dnf install -y \
    wget \
    make \
    cmake \
    git \
    wget \
    gcc \
    gcc-c++ \
    kernel-headers \
    glibc-devel \
    net-tools \
    glibc-headers \
    pciutils \
    unzip \
    xorg-x11-xauth \
    yum-utils \
    python39 \
    iproute \
    zlib-devel \
    binutils \
    vim \
    && dnf clean all

# Install other required packages from Fedora repos
# (not requiring a RHEL subscription)
# .repo files obtained from Fedora container image
COPY files/fedora-cisco-openh264.repo /etc/yum.repos.d/fedora-cisco-openh264.repo
COPY files/fedora-updates-testing.repo /etc/yum.repos.d/fedora-updates-testing.repo
COPY files/fedora-updates.repo /etc/yum.repos.d/fedora-updates.repo
COPY files/fedora.repo /etc/yum.repos.d/fedora.repo

RUN dnf install -y \
    --enablerepo=fedora-cisco-openh264 \
    --enablerepo=updates \
    --enablerepo=fedora \
    numactl \
    numactl-devel \
    nfs-utils \
    perf \
    tcpdump \
    && dnf clean all

RUN mkdir -p /opt/trex && cd /opt/trex && git clone --branch ${TREX_VER} ${TREX_REPO}
RUN cd /opt/trex/trex-core/linux_dpdk && \
    ./b configure --no-mlx --no-bxnt --new-memory && \
    cp dpdk_config.h /opt/trex/trex-core/src/ && \
    ./b build

RUN cd /opt && git clone ${TRAFFICGEN_REPO}
RUN pip3 install kubernetes

ENV PYTHONPATH="/opt/trex/trex-core/scripts/automation/trex_control_plane/interactive"
WORKDIR /opt/trex/trex-core/scripts
ENV TREX_DIR="/opt/trex/trex-core/scripts"
ENV TRAFFICGEN_DIR="/opt/trafficgen"

# Copy scripts
COPY scripts /usr/local/bin
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/
