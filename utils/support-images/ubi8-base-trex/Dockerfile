FROM registry.access.redhat.com/ubi8/ubi:latest

# Install required packages for trex
RUN dnf install -y \
    numactl \
    numactl-devel \
    rdma-core \
    rdma-core-devel \
    nfs-utils \
    perf \
    tcpdump \
    sudo \
    && dnf clean all
