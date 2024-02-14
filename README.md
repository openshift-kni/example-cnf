Example CNF
==============

[![PR Validation](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml/badge.svg)](https://github.com/openshift-kni/example-cnf/actions/workflows/push.yaml)

Example CNF is an OpenShift workload to exercice an SRIOV setup.

![Schema](documentation/schema.png)

It is providing the following operators:

* testpmd-operator
* trex-operator
* testpmd-lb-operator
* cnf-app-mac-operator

You can use them from the [Example CNF Catalog](https://quay.io/repository/rh-nfv-int/nfv-example-cnf-catalog?tab=tags).

How operators are created
------------------------

The four operators defined in this repository are built with [Operator SDK tool](https://sdk.operatorframework.io/docs/building-operators/).

We can differentiate between these two cases:

**Ansible-based operators:**

This is the case of testpmd-operator, trex-operator and testpmd-lb-operator.

Base structure for each case is achieved with the following commands, then it's just a matter of accommodating the required code for each operator in the corresponding files and folders:

- testpmd-operator

TBD

- trex-operator

TBD

- testpmd-lb-operator

```
$ mkdir testpmd-lb-operator; cd testpmd-lb-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind LoadBalancer
```

**Go-based operators:**

This is the case of cnf-app-mac-operator.

Base structure for this case is achieved with the following commands, then it's just a matter of accommodating the required code for the operator in the corresponding files and folders:

- cnf-app-mac-operator

For operator-sdk v1.33.0, you need to have installed the same Go version used in operator-sdk, which is go 1.22.5.

```
$ operator-sdk version
operator-sdk version: "v1.33.0", commit: "542966812906456a8d67cf7284fc6410b104e118", kubernetes version: "1.27.0", go version: "go1.21.5", GOOS: "linux", GOARCH: "amd64"
```

Create the project structure and the CNFAppMac API:

```
$ mkdir cnf-app-mac-operator; cd cnf-app-mac-operator
$ operator-sdk init --domain openshift.io --repo github.com/openshift-kni/example-cnf/tree/main/cnf-app-mac-operator
$ operator-sdk create api --version v1 --group examplecnf --kind CNFAppMac --controller --resource
```

At this point, remove RBAC resource creation in Makefile > manifests task. Then, review cmd/main.go and api/v1/cnfappmac_types.go, then run:

```
$ make generate
$ make manifests 
```

Create webhook and certmanager:

```
$ operator-sdk create webhook --version v1 --group examplecnf --kind CNFAppMac --defaulting --programmatic-validation
```

Review the generated files properly, then:

```
$ make manifests
```

Comment webhook references in PROJECT and cmd/main.go files (older versions were not using this), review internal/controller/cnfappmac_controller.go and review the rest of files.

To conclude, build the main.go file to check it's working fine:

```
$ go build cmd/main.go
```

Ansible based automation
------------------------

You can use the Ansible playbooks and roles at <https://github.com/rh-nfv-int/nfv-example-cnf-deploy> to automate the use of the Example CNF.

Traffic Flow
------------------------

![Flow](documentation/trex_flow_4_ports_bi_directional.png)

Traffic Flow:

- TRex (Traffic Generator) generates and sends traffic from Port 0 to TestPMD.

- TestPMD (Packet Manipulation Daemon), configured as a load balancer, receives incoming traffic on Ports 0 and 1.

- TestPMD load balances the incoming traffic between its Ports 2 and 3.

- TestPMD forwards the load-balanced traffic to the CNF Application.

- The CNF Application receives incoming traffic from TestPMD on one of its ports.

- The CNF Application processes the received traffic and passes it back to TRex for evaluation.

- TRex receives the processed traffic on Port 1.

- TRex calculates statistics by comparing the incoming traffic on Port 1 (processed traffic) with the outgoing traffic on Port 0 (original traffic sent by TRex) and vice versa.

This configuration simulates a traffic flow from TRex to TestPMD, then to the CNF Application, and finally back to TRex for evaluation. TestPMD serves as a load balancer to distribute traffic between its ports, and the CNF Application processes and loops back the traffic to TRex for analysis. TestPMD LB ensures zero traffic loss throughout the rolling update process.

Utils
------------------------

Under [utils](utils) folder, you can find some utilities included in example-cnf to extend the functionalities offered by the tool.

- [webserver.go](utils/webserver.go): a Golang-based webserver to implement liveness, readiness and startup probes in the container images offered in [cnf-app-mac-operator](cnf-app-mac-operator), [testpmd-container-app](testpmd-container-app) and [trex-container-app](trex-container-app) folders. The Makefiles offered in these directories take care of copying the webserver code from the utils directory to each image's directory.
