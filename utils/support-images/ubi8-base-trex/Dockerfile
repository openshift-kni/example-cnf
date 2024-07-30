FROM registry.access.redhat.com/ubi8/ubi:latest

# Install required packages for trex
RUN dnf install -y \
    numactl \
    numactl-devel \
    nfs-utils \
    perf \
    tcpdump \
    && dnf clean all
