import random
import string
from kubernetes import client, config, watch
from kubernetes.client.rest import ApiException

from logger import log


def create_event(data):
    group = "examplecnf.openshift.io"
    version = "v1"
    namespace = "example-cnf"
    plural = "trexconfigs"

    config.load_incluster_config()
    try:
        custom_api = client.CustomObjectsApi()
        objs = custom_api.list_namespaced_custom_object(group, version, namespace, plural)
    except ApiException as e:
        log.info("Exception when calling CustomObjectsApi->list_namespaced_custom_object: %s\n" % e)
        return

    if len(objs['items']) == 0:
        log.info("no trexconfig objects")
        return

    trex_config_name = objs['items'][0]['metadata']['name']
    trex_config_uid = objs['items'][0]['metadata']['uid']
    trex_config_api_version = objs['items'][0]['apiVersion']

    evtTimeMicro = data['microtime']
    evtTime = data['time']
    evtName = trex_config_name + '-' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))

    cr = {  'apiVersion': 'events.k8s.io/v1beta1',
            'kind': 'Event',
            'metadata': {
               'name': evtName,
               'namespace': namespace,
               'ownerReferences': []
            },
            'type': 'Normal',
            'eventTime': evtTimeMicro,
            'deprecatedLastTimestamp': evtTime,
            'deprecatedFirstTimestamp': evtTime,
            'reason': data['reason'],
            'action': data['reason'],
            'note': data['msg'],
            'regarding': {
                    'namespace': namespace,
                    'kind': 'TRexConfig',
                    'name': trex_config_name,
                    'uid': trex_config_uid
                },
            'reportingController': 'pod/' + os.environ['HOSTNAME'],
            'reportingInstance': trex_config_name
         }

    cr['metadata']['ownerReferences'].append({
            'apiVersion': trex_config_api_version,
            'kind': 'TRexConfig',
            'name': trex_config_name,
            'uid': trex_config_uid,
            'controller': True
        })

    events_api = client.EventsV1beta1Api()
    try:
        resp = events_api.create_namespaced_event(namespace, cr)
    except ApiException as e:
        log.info("Exception on creating Event: %s\n" % e)
