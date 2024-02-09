import random
import string
import os
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from kubernetes.config.config_exception import ConfigException

from logger import log


def create_event(data):
    group = "examplecnf.openshift.io"
    version = "v1"
    namespace = "example-cnf"
    plural = "trexapps"
    name = os.environ.get("CR_NAME")

    try:
        config.load_incluster_config()
    except ConfigException as e:
        log.error("Exception when setting incluster config: %s\n" % e)
        return

    custom_api = client.CustomObjectsApi()
    try:
        cr = custom_api.get_namespaced_custom_object(group, version, namespace, plural, name)
    except ApiException as e:
        log.info("Exception when trying to retrieve TRex CR object: %s\n" % e)
        return

    # Randomize the event name to allow for sending subsequent events
    random_event_id = '-' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    cr_event = {
        'apiVersion': 'events.k8s.io/v1',
        'kind': 'Event',
        'metadata': {
            'name': cr['metadata']['name'] + random_event_id,
            'namespace': cr['metadata']['namespace'],
            'ownerReferences': [{
                'apiVersion': cr['apiVersion'],
                'kind': cr['kind'],
                'name': cr['metadata']['name'],
                'uid': cr['metadata']['uid'],
                'controller': True
            }]
        },
        'type': 'Normal',
        'eventTime': data['microtime'],
        'series': {
            'lastObservedTime': data['time'],
            'count': 2
        },
        'reason': data['reason'],
        'action': data['reason'],
        'note': data['msg'],
        'regarding': {
            'namespace': cr['metadata']['namespace'],
            'kind': cr['kind'],
            'name': cr['metadata']['name'],
            'uid': cr['metadata']['uid']
        },
        'reportingController': 'pod/' + os.environ['HOSTNAME'],
        'reportingInstance': cr['metadata']['name']
    }
    log.info(f"CR to be utilized for event creation: {cr_event}")

    events_api = client.EventsV1Api()
    try:
        events_api.create_namespaced_event(namespace, cr_event)
    except ApiException as e:
        log.info("Exception when creating Event: %s\n" % e)
