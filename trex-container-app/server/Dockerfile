FROM docker.io/library/golang:1.23 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

## trex image
FROM quay.io/rh-nfv-int/ubi8-base-trex:v0.0.1

LABEL name="NFV Example TRexServer Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.13" \
      release="v0.2.13" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

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

# Create custom user to avoid using root account
RUN useradd example-cnf -u 56560

# This is to be able to manage some files that belong to root account
RUN usermod -a -G root example-cnf

# Allow example-cnf to use sudo permissions without asking for password
RUN echo -e "example-cnf\tALL=(ALL)\tNOPASSWD: ALL" > /etc/sudoers.d/example-cnf

# Create a folder managed by the custom user to place the config files to launch
RUN mkdir -p /usr/local/bin/example-cnf
RUN chmod 750 /usr/local/bin/example-cnf
RUN chown example-cnf /usr/local/bin/example-cnf

# Make sure trex_cfg.yaml is present in the proper folder and with proper permissions
RUN touch /usr/local/bin/example-cnf/trex_cfg.yaml
RUN chmod 664 /usr/local/bin/example-cnf/trex_cfg.yaml

# Copy scripts
COPY --chmod=550 scripts /usr/local/bin
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/webserver

# Move to the custom user
USER example-cnf
