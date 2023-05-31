## Build image
FROM quay.io/centos/centos:stream8 as build

ENV DPDK_VER=19.11
ENV DPDK_DIR=/usr/src/dpdk-${DPDK_VER}
ENV RTE_TARGET=x86_64-native-linuxapp-gcc
ENV RTE_SDK=${DPDK_DIR}

# Install prerequisite packages
RUN dnf groupinstall -y "Development Tools" && \
    dnf install --skip-broken -y wget numactl numactl-devel make libibverbs-devel logrotate rdma-core tcpdump && \
    dnf clean all

# Download the DPDK libraries
RUN wget http://fast.dpdk.org/rel/dpdk-${DPDK_VER}.tar.xz -P /usr/src && \
    tar -xpvf /usr/src/dpdk-${DPDK_VER}.tar.xz -C /usr/src && \
    rm -f /usr/src/dpdk-${DPDK_VER}.tar.xz

# Download dependencies
RUN git clone https://github.com/krsacme/testpmd-as-load-balancer.git $(pwd)/testpmd-as-load-balancer

# Configuration
RUN sed -i -e 's/EAL_IGB_UIO=y/EAL_IGB_UIO=n/' \
    -e 's/KNI_KMOD=y/KNI_KMOD=n/' \
    -e 's/LIBRTE_KNI=y/LIBRTE_KNI=n/' \
    -e 's/LIBRTE_PMD_KNI=y/LIBRTE_PMD_KNI=n/' $DPDK_DIR/config/common_linux && \
    sed -i 's/\(CONFIG_RTE_LIBRTE_MLX5_PMD=\)n/\1y/g' $DPDK_DIR/config/common_base

# Build it
RUN cd ${DPDK_DIR} && \
    make install T=${RTE_TARGET} DESTDIR=${RTE_SDK} -j $(nproc)

RUN cp -af $(pwd)testpmd-as-load-balancer/v19.11/test-pmd ${DPDK_DIR}/app/test-pmd && \
    cd ${DPDK_DIR}/app/test-pmd && \
    make -j $(nproc) && \
    cp testpmd /usr/local/bin

## testpmd image
FROM quay.io/centos/centos:stream8

# Required libraries and debugging tools
RUN dnf install -y \
    epel-release \
    libibverbs \
    logrotate \
    numactl \
    python3 \
    rdma-core \
    tcpdump \
    && dnf clean all

# copy testpmd runtime cmdline file
COPY testpmd-runtime-cmds.txt /root/testpmd-runtime-cmds.txt
COPY scripts /usr/local/bin
COPY --from=build /usr/local/bin/testpmd /usr/local/bin/testpmd
