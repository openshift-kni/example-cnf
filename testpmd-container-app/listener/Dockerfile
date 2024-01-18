FROM docker.io/library/golang:1.21 as build

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-39:latest
USER root
RUN pip3 install kubernetes

# Copy scripts
COPY scripts /usr/local/bin
COPY --chmod=550 --from=build /utils/webserver /usr/local/bin/

ENTRYPOINT ["testpmd-wrapper"]
