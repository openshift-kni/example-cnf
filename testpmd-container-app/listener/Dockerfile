FROM docker.io/library/golang:1.21 as build

WORKDIR /scripts
COPY scripts/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

FROM registry.access.redhat.com/ubi8/python-39:latest
USER root
RUN pip3 install kubernetes

# Copy scripts
COPY scripts /usr/local/bin
COPY --from=build /scripts/webserver /usr/local/bin/

# Update permissions
RUN chmod +x /usr/local/bin/webserver

ENTRYPOINT ["testpmd-wrapper"]
