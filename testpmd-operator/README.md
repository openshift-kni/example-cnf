# testpmd-operator

![Operator behavior](../documentation/testpmd-operator.png)

Final application, also known as CNF Application, which is a standard TestPMD instance using the default MAC forwarding module. It uses two components:

- TestPMD CR, which creates a pod to implement the MAC forwarding module as final application. Related pod is `testpmd-app-<x>` pod (only one replica is used).
- TestPMD Operator, ensuring CR reconciliation via controller-manager pod. Related pod is `testpmd-operator-controller-manager-<x>` pod.

The following information can be extracted from pod logs:

- To see the TestPMD statistics printed periodically for this module, you can rely on `testpmd-app-<x>` pod logs.
- In `testpmd-operator-controller-manager-<x>` pod, you can see the execution of the Ansible playbooks that ensures the reconciliation loop of the operator.

## How to build the operator

Base structure is achieved with the following commands, then it's just a matter of accommodating the required code for the operator in the corresponding files and folders:

```
$ mkdir testpmd-operator; cd testpmd-operator
$ operator-sdk init --domain openshift.io --plugins ansible
$ operator-sdk create api --version v1 --generate-role --group examplecnf --kind TestPMD
```

## What to update if bumping operator version

Apart from the modifications you have to do, you also need to update the operator version in these files:

- [CHANGELOG.md](CHANGELOG.md).
- [Makefile](Makefile).
- [Dockerfile](Dockerfile).

Also, make sure that the operator version is within the interval defined in [required-annotations.yaml](../utils/required-annotations.yaml) file for `olm.skipRange` annotation, else update that file to modify the current range.

A classical change is the update of Operator SDK version used in the operator. Here's an [example](https://github.com/openshift-kni/example-cnf/pull/108) where this is done.
