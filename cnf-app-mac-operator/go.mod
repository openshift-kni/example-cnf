module github.com/rh-nfv-int/cnf-app-mac-operator

go 1.13

require (
	github.com/go-logr/logr v0.2.0
	github.com/k8snetworkplumbingwg/network-attachment-definition-client v1.1.0
	github.com/onsi/ginkgo v1.16.4
	github.com/onsi/gomega v1.19.0
	k8s.io/api v0.18.10
	k8s.io/apimachinery v0.18.10
	k8s.io/client-go v0.18.10
	sigs.k8s.io/controller-runtime v0.6.3
	sigs.k8s.io/kustomize/kustomize/v5 v5.0.1 // indirect
)
