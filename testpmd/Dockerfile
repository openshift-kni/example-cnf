FROM centos:latest

ENV DPDK_VER 19.11
ENV DPDK_DIR /usr/src/dpdk-${DPDK_VER}
ENV RTE_TARGET=x86_64-native-linuxapp-gcc
ENV RTE_SDK=${DPDK_DIR}

# Install prerequisite packages
RUN yum groupinstall -y "Development Tools" && \
    yum install --skip-broken -y wget numactl numactl-devel make libibverbs-devel logrotate rdma-core && \
    yum clean all

# Download the DPDK libraries
RUN wget http://fast.dpdk.org/rel/dpdk-${DPDK_VER}.tar.xz -P /usr/src && \
    tar -xpvf /usr/src/dpdk-${DPDK_VER}.tar.xz -C /usr/src && \
    rm -f /usr/src/dpdk-${DPDK_VER}.tar.xz

# Configuration
RUN sed -i -e 's/EAL_IGB_UIO=y/EAL_IGB_UIO=n/' \
      -e 's/KNI_KMOD=y/KNI_KMOD=n/' \
      -e 's/LIBRTE_KNI=y/LIBRTE_KNI=n/' \
      -e 's/LIBRTE_PMD_KNI=y/LIBRTE_PMD_KNI=n/' $DPDK_DIR/config/common_linux && \
    sed -i 's/\(CONFIG_RTE_LIBRTE_MLX5_PMD=\)n/\1y/g' $DPDK_DIR/config/common_base

# PATCH
COPY v3-bus-pci-fix-VF-bus-error-for-memory-access.diff ./v3-bus-pci-fix-VF-bus-error-for-memory-access.diff
RUN cd ${DPDK_DIR} && git apply /v3-bus-pci-fix-VF-bus-error-for-memory-access.diff

RUN git clone https://github.com/krsacme/testpmd-as-load-balancer.git /opt && \
    cp /opt/v19.11/test-pmd ${DPDK_DIR}/app -r

# Build it
RUN cd ${DPDK_DIR} && \
    make install T=${RTE_TARGET} DESTDIR=${RTE_SDK} -j 8

# Build TestPmd
RUN cd ${DPDK_DIR}/app/test-pmd && \
    make && \
    cp testpmd /usr/local/bin

# macaddr DPDK application
COPY macaddr ${DPDK_DIR}/examples/macaddr/

RUN cd ${DPDK_DIR}/examples/macaddr && \
    make && \
    cp ${DPDK_DIR}/examples/macaddr/build/app/macaddr /usr/local/bin

# python required for expand-cpu util
RUN yum install -y python3 && yum clean all

# copy testpmd runtime cmdline file
COPY testpmd-runtime-cmds.txt /root/testpmd-runtime-cmds.txt
COPY scripts /usr/local/bin
