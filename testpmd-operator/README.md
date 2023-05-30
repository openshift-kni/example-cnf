testpmd-operator
================

Ansible based operator to deploy TestPMD application in OpenShift.

Container images for the TestPMD application is built using [testpmd-container-app](https://github.com/krsacme/testpmd-container-app). 

Preparation
----------
* Deploy a OpenShift cluster with Baremetal worker nodes
* Deploy Performance Addon Operator and configure nodes with ``worker-cnf`` role
* Deploy SR-IOV Network Operator
* Create Peformance Profile
* Create SR-IOV Network Policy and Network

TestPMD operator deployment
---------------------------
Deploy the operator
```
git clone https://github.com/krsacme/testpmd-operator.git
cd testpmd-operator
oc kustomize | oc -n example-cnf apply -f -
```

Modify the CR as per the cluster and create it:
```
oc -n example-cnf apply -f deploy/crds/examplecnf.openshift.io_v1_testpmd_cr.yaml
```
