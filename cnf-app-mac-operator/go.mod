module github.com/rh-nfv-int/cnf-app-mac-operator

go 1.13

require (
	github.com/go-logr/logr v0.1.0
	github.com/k8snetworkplumbingwg/network-attachment-definition-client v1.1.0
	github.com/onsi/ginkgo v1.12.1
	github.com/onsi/gomega v1.10.1
	k8s.io/api v0.18.10
	k8s.io/apimachinery v0.18.10
	k8s.io/client-go v0.18.10
	sigs.k8s.io/controller-runtime v0.6.3
	sigs.k8s.io/kustomize/kustomize/v3 v3.8.7 // indirect
)
