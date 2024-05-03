## Build image
FROM quay.io/centos/centos:stream8 as build

ENV DPDK_VER=23.11
ENV DPDK_DIR=/usr/src/dpdk-${DPDK_VER}

# Install prerequisite packages
RUN dnf groupinstall -y "Development Tools" && \
    dnf install --skip-broken -y wget numactl numactl-devel gcc libibverbs-devel logrotate rdma-core tcpdump python39 && \
    dnf clean all

# Install Meson, Ninja and pyelftools packages with pip, required to build DPDK. Python >= 3.7 is required
RUN pip3.9 install meson ninja pyelftools

# Download the DPDK libraries
RUN wget http://fast.dpdk.org/rel/dpdk-${DPDK_VER}.tar.xz -P /usr/src && \
    tar -xpvf /usr/src/dpdk-${DPDK_VER}.tar.xz -C /usr/src && \
    rm -f /usr/src/dpdk-${DPDK_VER}.tar.xz

# Build it with support for mlx5 driver
RUN cd ${DPDK_DIR} && \
    meson setup -Dc_args='-DRTE_LIBRTE_MLX5_DEBUG' -Dexamples=all -Dplatform=generic build && \
    cd build && \
    ninja && \
    meson install && \
    ldconfig && \
    cp app/dpdk-testpmd /usr/local/bin

## Image to build webserver
FROM docker.io/library/golang:1.21 as build2

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

## testpmd image
# Use ubi8/ubi as image
FROM registry.access.redhat.com/ubi8/ubi:latest

MAINTAINER telcoci@redhat.com

LABEL name="NFV Example CNF Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.8" \
      release="v0.2.8" \
      summary="An example CNF for platform valiation" \
      description="An example CNF for platform valiation"

COPY licenses /licenses

# Install prerequisite packages from UBI repos
RUN dnf install -y \
    libibverbs \
    logrotate \
    python3 \
    && dnf clean all

# Install prerequisite packages from CentOS Stream repos
COPY files/centos8-base.repo /etc/yum.repos.d/centos8-base.repo
COPY files/centos8-app.repo /etc/yum.repos.d/centos8-app.repo
COPY files/centos8-extras.repo /etc/yum.repos.d/centos8-extras.repo

RUN dnf install -y \
    --enablerepo=centos8-base \
    --enablerepo=centos8-app \
    --enablerepo=centos8-extras \
    epel-release \
    numactl \
    rdma-core \
    tcpdump \
    && dnf clean all

# Copy scripts
COPY --chmod=550 --from=build2 /utils/webserver /usr/local/bin/
COPY --chmod=550 --from=build /usr/local/bin/dpdk-testpmd /usr/local/bin/testpmd
COPY --chmod=550 scripts/testpmd-run /usr/local/bin/testpmd-run

# Prepare entrypoint
ENTRYPOINT ["/usr/local/bin/testpmd-run"]
