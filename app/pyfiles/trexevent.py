import random
import string
from kubernetes import client, config, watch
from kubernetes.client.rest import ApiException

from logger import log


def create_event(data):
    group = "examplecnf.openshift.io"
    version = "v1"
    namespace = "example-cnf"
    plural = "trexapps"
    name = os.environ.get("CR_NAME")

    config.load_incluster_config()
    custom_api = client.CustomObjectsApi()
    try:
        objs = custom_api.list_namespaced_custom_object(group, version, namespace, plural)
    except ApiException as e:
        log.info("Exception when calling CustomObjectsApi->list_namespaced_custom_object: %s\n" % e)
        return

    if len(objs['items']) == 0:
        log.info("cannot create event, no trexapps CR object")
        return

    if len(objs['items']) > 1:
        try:
            cr_obj = custom_api.get_namespaced_custom_object(group, version, namespace, plural, name)
        except ApiException as e:
            log.info("Exception when calling CustomObjectsApi->get_namespaced_custom_object: %s\n" % e)
            return
    else:
        cr_obj = objs['items'][0]

    trex_config_name = cr_obj['metadata']['name']
    trex_config_uid = cr_obj['metadata']['uid']
    trex_config_api_version = cr_obj['apiVersion']

    evtTimeMicro = data['microtime']
    evtTime = data['time']
    evtName = trex_config_name + '-' + ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))

    cr = {
            'apiVersion': 'events.k8s.io/v1beta1',
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
                    'kind': 'TRexApp',
                    'name': trex_config_name,
                    'uid': trex_config_uid
                },
            'reportingController': 'pod/' + os.environ['HOSTNAME'],
            'reportingInstance': trex_config_name
         }

    cr['metadata']['ownerReferences'].append({
            'apiVersion': trex_config_api_version,
            'kind': 'TRexApp',
            'name': trex_config_name,
            'uid': trex_config_uid,
            'controller': True
        })

    events_api = client.EventsV1beta1Api()
    try:
        resp = events_api.create_namespaced_event(namespace, cr)
    except ApiException as e:
        log.info("Exception on creating Event: %s\n" % e)
