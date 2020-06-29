testpmd-operator
================

Ansible based operator to deploy TestPMD application in OpenShift.

Container images for the TestPMD application is built using [testpmd-container-app](https://github.com/krsacme/testpmd-container-app). 

Preparation
----------
* Deploy a OpenShift cluster with Baremetal worker nodes

* Baremetal Node Configuration (Kernel args and IOMMU)
```
# TODO

```

* Configure static CPU manager for Kubelet configuration
```
NODENAME=worker-0
oc label node $NODENAME cpumanager=true
oc label machineconfigpool worker custom-kubelet=cpumanager-enabled
git clone https://github.com/krsacme/ocp-templates-nfv.git
cd ocp-templates-nfv
oc -n openshift-machine-api apply -f cpumanager-kubeletconfig.yaml
```

* Deploy ``sriov-network-operator`` (simplest way is to deploy via source)
```
go get github.com/openshift/sriov-network-operator
export KUBECONFIG=/home/kni/dev-scripts/ocp/vnf/auth/kubeconfig
make deploy-setup

# Disable webhook (to disable PF whitelisting)
oc -n openshift-sriov-network-operator patch sriovoperatorconfig default --type=merge -p '{"spec":{"enableOperatorWebhook":false}}'
```
* Create SR-IOV networks & policy, modify the ``policy1.yaml`` file as per the cluster interface names
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

```
oc -n example-cnf apply -f deploy/crds/examplecnf.openshift.io_testpmds_crd.yaml
oc -n example-cnf apply -f deploy/service_account.yaml
oc -n example-cnf apply -f deploy/role.yaml
oc -n example-cnf apply -f deploy/role_binding.yaml
oc -n example-cnf apply -f deploy/operator.yaml
oc -n example-cnf apply -f deploy/scc.yaml

oc -n example-cnf apply -f deploy/crds/examplecnf.openshift.io_v1_testpmd_cr.yaml
```
