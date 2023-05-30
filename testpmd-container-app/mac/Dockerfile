FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
WORKDIR /
ADD ./sriov-4.4 /
ADD ./sriov-4.5 /
ADD ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
