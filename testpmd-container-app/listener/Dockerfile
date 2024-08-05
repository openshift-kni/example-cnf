FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-39:latest

LABEL name="NFV Example Listener Application" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.11" \
      release="v0.2.11" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

USER root
RUN pip3 install kubernetes

# Copy scripts
COPY --chmod=550 scripts /usr/local/bin
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/

USER 65532:65532

ENTRYPOINT ["testpmd-wrapper"]
