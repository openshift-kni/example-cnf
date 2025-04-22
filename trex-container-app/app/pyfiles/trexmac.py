import json

from kubernetes import client, config
from kubernetes.client.rest import ApiException

from logger import log

def get_dst_mac():
    macs = []

    config.load_incluster_config()
    v1 = client.CoreV1Api()
    try:
        response = v1.list_namespaced_pod(namespace="example-cnf", label_selector="example-cnf-type=cnf-app")
        # there is only one pod that matches this label, so let's iterate the networks over it
        networks = json.loads(response.items[0].metadata.annotations['k8s.v1.cni.cncf.io/networks'])

        for network in networks:
            log.info("get_dst_mac - MAC found: %s" % network.get("mac"))
            macs.append(network["mac"])

        log.info("get_dst_mac - All MACs found: %s", ','.join(macs))
        return macs
    except ApiException as e:
        log.error("Error: %s" % e)
        return []
