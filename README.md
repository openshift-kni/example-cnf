testpmd-operator
================

Ansible based operator to deploy TestPMD application in OpenShift.

Container images for the TestPMD application is built using [testpmd-container-app](https://github.com/krsacme/testpmd-container-app). 

Preparation
----------
* Deploy a OpenShift cluster with Baremetal worker nodes

* Baremetal Node Configuration (Kernel args and IOMMU)
```
go get github.com/openshift-kni/performance-addon-operators
cd $GOPATH/src/github.com/openshift-kni/performance-addon-operators
CLUSTER=manual make cluster-deploy
make cluster-label-worker-cnf
CLUSTER=manual make cluster-wait-for-mcp

cd $HOME
git clone https://github.com/krsacme/ocp-templates-nfv.git
cd ~/ocp-templates-nfv
# Configure CPUs
oc apply -f performance_profile.yaml
```

* Deploy ``sriov-network-operator`` (simplest way is to deploy via source)
```
go get github.com/openshift/sriov-network-operator
export KUBECONFIG=/home/kni/dev-scripts/ocp/vnf/auth/kubeconfig
cd $GOPATH/src/github.com/openshift/sriov-network-operator
make deploy-setup

# Wait till sriovoperatorconfig creating
# Disable webhook (to disable PF whitelisting)
oc -n openshift-sriov-network-operator patch sriovoperatorconfig default --type=merge -p '{"spec":{"enableOperatorWebhook":false}}'
```

* Create SR-IOV networks & policy, modify the ``policy1.yaml`` file as per the cluster interface names
```
cd $HOME
git clone https://github.com/krsacme/ocp-templates-nfv.git
cd ocp-templates-nfv
oc kustomize sriov/ | oc apply -f -
```

TestPMD operator deployment
---------------------------
Ensure the node on which the TestPMD application should run has a
label ``app: testpmd``, by executing below command:
```
oc label node worker-1 app=testpmd
```


Deploy the operator
```
make cluster-deploy

# Modify the CR as per the need
oc -n example-cnf apply -f deploy/crds/examplecnf.openshift.io_v1_testpmd_cr.yaml
```
