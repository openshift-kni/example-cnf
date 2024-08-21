FROM registry.access.redhat.com/ubi8/ubi:latest

# Install EPEL from Fedora
RUN dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# Install other required packages for testpmd
RUN dnf install -y \
    libibverbs \
    logrotate \
    python3 \
    numactl \
    rdma-core \
    tcpdump \
    sudo \
    && dnf clean all
