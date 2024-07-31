FROM registry.access.redhat.com/ubi8/ubi:latest

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
