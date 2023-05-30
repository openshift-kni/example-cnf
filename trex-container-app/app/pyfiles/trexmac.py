from datetime import datetime
from dateutil import parser
from dateutil.tz import tzutc
from kubernetes import client, config, watch
from kubernetes.client.rest import ApiException

from logger import log


def watch_cr(queue):
    group = "examplecnf.openshift.io"
    version = "v1"
    namespace = os.environ.get("NAMESPACE", "example-cnf")
    plural = "cnfappmacs"

    config.load_incluster_config()
    custom_api = client.CustomObjectsApi()
    w = watch.Watch()
    now = datetime.utcnow().replace(tzinfo=tzutc())
    for event in w.stream(custom_api.list_namespaced_custom_object,
                          group=group, version=version, plural=plural, namespace=namespace):
        if event['type'] == 'ADDED':
            meta = event['object']['metadata']
            spec = event['object']['spec']
            created = parser.parse(meta['creationTimestamp'])
            if created > now:
                queue.put(event['object'])

def get_macs(spec):
    macs = []
    for resource in spec['resources']:
        for device in resource['devices']:
            macs.append(device['mac'])
    log.info("macs list - %s" % ",".join(macs))
    return macs

def get_cnfappmac_cr_values():
    group = "examplecnf.openshift.io"
    version = "v1"
    namespace = "example-cnf"
    plural = "cnfappmacs"

    config.load_incluster_config()
    custom_api = client.CustomObjectsApi()
    try:
        resp = custom_api.list_namespaced_custom_object(group, version, namespace, plural)
        for item in resp['items']:
            macs = get_macs(item['spec'])
            return macs
    except ApiException as e:
        return None
