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
```
git clone https://github.com/krsacme/ocp-templates-nfv.git
cd ocp-templates-nfv
oc apply -f performance-profile.yaml
```

* Create SR-IOV Network Policy and Network
```
git clone https://github.com/krsacme/ocp-templates-nfv.git
cd ocp-templates-nfv
oc apply -f sriov/policy1.yaml
oc apply -f sriov/policy2.yaml
oc apply -f sriov/network1.yaml
oc apply -f sriov/network2.yaml
```

TestPMD operator deployment
---------------------------
Deploy the operator
```
git clone https://github.com/krsacme/testpmd-operator.git
cd testpmd-operator
oc kustomize | oc -n example-cnf apply -f -
```

Configure the resources in the CR and create it
```
oc -n example-cnf apply -f deploy/crds/examplecnf.openshift.io_v1_testpmd_cr.yaml
```
