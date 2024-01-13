FROM registry.access.redhat.com/ubi8/python-39:latest
USER root
RUN pip3 install kubernetes

# Install Go binary
ARG GO_VERSION=go1.21.6
ADD https://go.dev/dl/$GO_VERSION.linux-amd64.tar.gz /usr/local
RUN tar -C /usr/local -xzf /usr/local/$GO_VERSION.linux-amd64.tar.gz
RUN rm /usr/local/$GO_VERSION.linux-amd64.tar.gz
ENV PATH="$PATH:/usr/local/go/bin"

COPY scripts /usr/local/bin
RUN chmod +x /usr/local/bin/webserver.go
ENTRYPOINT ["testpmd-wrapper"]
