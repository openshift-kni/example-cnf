FROM registry.access.redhat.com/ubi9/ubi:latest

# Install EPEL from Fedora
RUN dnf install -y \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install other required packages for grout
RUN dnf install -y \
    libibverbs \
    logrotate \
    python3 \
    numactl \
    rdma-core \
    tcpdump \
    sudo \
    && dnf clean all
