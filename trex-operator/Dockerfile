FROM quay.io/operator-framework/ansible-operator:v1.10.0

MAINTAINER telcoci@redhat.com

LABEL name="NFV Example CNF TRex Operator" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.6" \
      release="v0.2.6" \
      summary="An example CNF for platform valiation" \
      description="An example CNF for platform valiation"

COPY licenses /licenses

USER root
RUN yum -y update-minimal --setopt=tsflags=nodocs \
        --security --sec-severity=Important --sec-severity=Critical
USER ansible

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
