## Build image
FROM quay.io/rh-nfv-int/dpdk-19.11:v0.0.1 as build

## Image to build webserver
FROM docker.io/library/golang:1.21 as build2

WORKDIR /utils
COPY utils/webserver.go .
RUN go mod init webserver.go
RUN GOOS=linux CGO_ENABLED=0 go build -a -o webserver .

## testpmd image
FROM quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1

# copy testpmd runtime cmdline file
COPY testpmd-runtime-cmds.txt /root/testpmd-runtime-cmds.txt

# Copy scripts
COPY scripts /usr/local/bin
COPY --chmod=550 --from=build2 /utils/webserver /usr/local/bin/
COPY --from=build /usr/local/bin/testpmd /usr/local/bin/testpmd
