FROM quay.io/operator-framework/ansible-operator:v1.35.0

LABEL name="NFV Example CNF Application Opertor" \
      maintainer="telcoci@redhat.com" \
      vendor="fredco" \
      version="v0.2.18" \
      release="v0.2.18" \
      summary="An example CNF for platform validation" \
      description="An example CNF for platform validation"

COPY licenses /licenses

RUN /usr/bin/python3 -m pip install openshift

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
