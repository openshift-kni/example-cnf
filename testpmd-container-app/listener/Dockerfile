FROM registry.access.redhat.com/ubi8/python-39:latest
USER root
RUN pip3 install kubernetes
COPY scripts /usr/local/bin
ENTRYPOINT ["testpmd-wrapper"]
