# cnf-app-mac-operator

![Operator behavior](../documentation/cnf-app-mac-operator.png)

Auxiliary operator just composed by one component, which is CNFAppMac Operator, a Golang-based operator in charge of ensuring reconciliation for CNFAppMac CR, which is a wrapper created for the CNFApp pod (either testpmd or grout) and linked to it, and that is used to extract the network information of the pods (network, MAC, IP and PCI addresses), to be offered to other components of the solution.

The CR is created once the CNFApp pod is created. The reconciliation loop of the CNFAppMac CR, once created, keeps listening to the Kubernetes API till deploying a pod labelled as `cnf-app`.

## How to build the operator

Base structure for this case is achieved with the following commands, then it's just a matter of accommodating the required code for the operator in the corresponding files and folders:

For operator-sdk v1.39.1, you need to have installed the same Go version used in operator-sdk, which is at least Go 1.23.4+.

```
$ operator-sdk version
operator-sdk version: "v1.39.1", commit: "b8a728e15447465a431343a664e9a27ff9db655e", kubernetes version: "1.31.0", go version: "go1.23.4", GOOS: "linux", GOARCH: "amd64"
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

## What to update if bumping operator version

Apart from the modifications you have to do, you also need to update the operator version in these files:

- [CHANGELOG.md](CHANGELOG.md).
- [Makefile](Makefile).
- [Dockerfile](Dockerfile).

Also, make sure that the operator version is within the interval defined in [required-annotations.yaml](../utils/required-annotations.yaml) file for `olm.skipRange` annotation, else update that file to modify the current range.

A common change is the update of Operator SDK version used in the operator. Here's an [example](https://github.com/openshift-kni/example-cnf/pull/108) where this is done.
