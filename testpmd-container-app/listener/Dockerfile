FROM registry.access.redhat.com/ubi8/python-39:latest
USER root
RUN pip3 install kubernetes
# Dependencies for lifecycle webserver
RUN pip3 install Flask waitress
COPY scripts /usr/local/bin
RUN chmod +x /usr/local/bin/webserver
ENTRYPOINT ["testpmd-wrapper"]
