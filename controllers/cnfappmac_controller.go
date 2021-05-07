/*


Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strings"

	"github.com/go-logr/logr"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/remotecommand"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	"sigs.k8s.io/controller-runtime/pkg/source"

	//netv1 "github.com/k8snetworkplumbingwg/network-attachment-definition-client/pkg/apis/k8s.cni.cncf.io/v1"

	examplecnfv1 "github.com/rh-nfv-int/cnf-app-mac-operator/api/v1"
)

// CNFAppMacReconciler reconciles a CNFAppMac object
type CNFAppMacReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// getWatchNamespace returns the Namespace the operator should be watching for changes
func getWatchNamespace() (string, error) {
	// WatchNamespaceEnvVar is the constant for env variable WATCH_NAMESPACE
	// which specifies the Namespace to watch.
	// An empty value means the operator is running with cluster scope.
	var watchNamespaceEnvVar = "WATCH_NAMESPACE"

	ns, found := os.LookupEnv(watchNamespaceEnvVar)
	if !found {
		return "example-cnf", nil
	}
	return ns, nil
}

func containsString(slice []string, s string) bool {
	for _, item := range slice {
		if item == s {
			return true
		}
	}
	return false
}

// +kubebuilder:rbac:groups=examplecnf.openshift.io,namespace=example-cnf,resources=cnfappmacs,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=examplecnf.openshift.io,namespace=example-cnf,resources=cnfappmacs/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=batch,namespace=example-cnf,resources=jobs,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups="",namespace=example-cnf,resources=pods;pods/exec;pods/log;secrets;configmaps,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=k8s.cni.cncf.io,namespace=example-cnf,resources=network-attachment-definitions,verbs=get;list;watch
// +kubebuilder:rbac:groups=security.openshift.io,namespace=example-cnf,resources=securitycontextconstraints,resourceNames=hostnetwork,verbs=use

func (r *CNFAppMacReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.Background()
	log := r.Log.WithValues("cnfappmac", req.NamespacedName)

	// TODO(skramaja): Used for local run, not required with deployment as manager will be setup with valid namespace
	watchNamespace, err := getWatchNamespace()
	if req.NamespacedName.Namespace != watchNamespace {
		return ctrl.Result{}, nil
	}

	// Request will be received for the Pod
	// Check the state of the Pod to be running
	pod := &corev1.Pod{}
	err = r.Get(ctx, req.NamespacedName, pod)
	if err != nil {
		if errors.IsNotFound(err) {
			// Might be deleted
			return ctrl.Result{}, nil
		}
		return ctrl.Result{}, err
	}

	isMarkedToBeDeleted := pod.GetDeletionTimestamp() != nil
	if isMarkedToBeDeleted {
		r.removeCR(req)
		return ctrl.Result{}, nil
	}

	if pod.Status.Phase != corev1.PodRunning {
		return ctrl.Result{}, nil
	}

	lbl, ok := pod.Labels["example-cnf-type"]
	if !ok || lbl != "cnf-app" {
		return ctrl.Result{}, nil
	}

	log.Info("Reconcile cnf application")

	// Check if the pod has additional networks via NetworkAttachmentDefinitions
	networkStr, ok := pod.Annotations["k8s.v1.cni.cncf.io/networks"]
	var networks []map[string]interface{}
	if ok {
		json.Unmarshal([]byte(networkStr), &networks)
		if len(networks) == 0 {
			return ctrl.Result{}, nil
		}
	} else {
		// CNF application, but does not have required annotations
		// This can be case of shift-on-stack where sriov-cnf will not work with annotations
		// Try alternate method
		err = r.getNetworksFromResources(req, pod, &networks)
		if err != nil {
			return ctrl.Result{}, err
		}
	}

	// Check if one of the nework has hardcode mac, pod will be skipped
	for _, item := range networks {
		if _, ok = item["mac"]; ok {
			return ctrl.Result{}, nil
		}
	}

	// Check if one of the network is SR-IOV Network
	// TODO(skramaja)

	// Check if the Mac CR is already created for this pod
	macCR := &examplecnfv1.CNFAppMac{}
	err = r.Get(ctx, req.NamespacedName, macCR)
	if err == nil {
		// CNFAppMac CR is found for this pod, skip further processing
		return ctrl.Result{}, nil
	} else if !errors.IsNotFound(err) {
		log.Error(err, "Failed to get cr")
		return ctrl.Result{}, err
	}

	var nwNameList []string
	log.Info("Pod Info", "Node", pod.Spec.NodeName)
	log.Info("Length", "l2", len(networks))
	for _, item := range networks {
		log.Info("Newtorks", "name", item["name"])
		if !containsString(nwNameList, item["name"].(string)) {
			nwNameList = append(nwNameList, item["name"].(string))
		}
	}

	var resources []string
	podName := req.NamespacedName.Name
	namespace := req.NamespacedName.Namespace
	for _, nwName := range nwNameList {
		// Get Resource name from the network name
		netAttach := &unstructured.Unstructured{}
		netAttach.SetKind("NetworkAttachmentDefinition")
		netAttach.SetAPIVersion("k8s.cni.cncf.io/v1")
		nmName := req.NamespacedName
		nmName.Name = nwName
		err = r.Get(ctx, nmName, netAttach)
		if err != nil {
			return ctrl.Result{}, err
		}
		resName := netAttach.GetAnnotations()["k8s.v1.cni.cncf.io/resourceName"]
		resName = strings.ReplaceAll(resName, "/", "_")
		resName = strings.ReplaceAll(resName, "-", "_")
		resName = strings.ReplaceAll(resName, ".", "_")
		resName = strings.ToUpper(resName)
		envName := "PCIDEVICE_" + resName

		pciValue, err := getContainerEnvValue(podName, namespace, envName)
		if err != nil {
			return ctrl.Result{}, err
		}
		pciValue = strings.TrimSuffix(pciValue, "\n")
		pciValue = strings.TrimSuffix(pciValue, "\r")
		pciList := strings.Split(pciValue, ",")
		resource := nwName + "," + netAttach.GetAnnotations()["k8s.v1.cni.cncf.io/resourceName"]
		for _, pci := range pciList {
			resource += "," + pci
		}
		resources = append(resources, resource)
	}

	err = r.createMacFetchJob(req, pod.Spec.NodeName, resources)
	if err != nil {
		return ctrl.Result{}, err
	}

	log.Info("Job created")
	return ctrl.Result{}, nil
}

func (r *CNFAppMacReconciler) getNetworksFromResources(req ctrl.Request, pod *corev1.Pod, networks *[]map[string]interface{}) error {
	ctx := context.Background()
	log := r.Log.WithValues("cnfappmac", req.NamespacedName)

	log.Info("getNet")

	// Get resources and networks via net-attach-def
	listObj := &unstructured.UnstructuredList{}
	opts := []client.ListOption{}
	listObj.SetGroupVersionKind(schema.GroupVersionKind{
		Group:   "k8s.cni.cncf.io",
		Version: "v1",
		Kind:    "NetworkAttachmentDefinitionList",
	})
	err := r.List(ctx, listObj, opts...)
	if err != nil {
		return err
	}

	for k, _ := range pod.Spec.Containers[0].Resources.Limits {
		netName, ok := r.getNetworkName(k, listObj)
		if ok {
			entry := map[string]interface{}{"name": netName}
			*networks = append(*networks, entry)
		}
	}
	return nil
}

func (r *CNFAppMacReconciler) getNetworkName(resource corev1.ResourceName, listObj *unstructured.UnstructuredList) (string, bool) {
	for _, net := range listObj.Items {
		for _, v := range net.GetAnnotations() {
			if v == string(resource) {
				return net.GetName(), true
			}
		}
	}
	return "", false
}

func (r *CNFAppMacReconciler) removeCR(req ctrl.Request) {
	ctx := context.Background()
	macCR := &examplecnfv1.CNFAppMac{}
	err := r.Get(ctx, req.NamespacedName, macCR)
	if err == nil {
		r.Delete(ctx, macCR)
	}

	macName := req.NamespacedName
	macName.Name = "mac-fetch-" + req.NamespacedName.Name
	job := &batchv1.Job{}
	err = r.Get(context.Background(), macName, job)
	if err == nil {
		r.Delete(ctx, job)
	}
}

func (r *CNFAppMacReconciler) createMacFetchJob(req ctrl.Request, nodeName string, resources []string) error {
	log := r.Log.WithValues("cnfappmac", req.NamespacedName)
	macName := req.NamespacedName
	macName.Name = "mac-fetch-" + req.NamespacedName.Name

	// Create a job on specific worker node to fetch the PCI's admin mac adress
	job := &batchv1.Job{}
	err := r.Get(context.Background(), macName, job)
	if err != nil && !errors.IsNotFound(err) {
		return err
	} else if err == nil {
		// Job for this pod already exists
		log.Info("Job already exits")
		return nil
	}

	args := []string{req.NamespacedName.Name}
	args = append(args, resources...)
	env := []corev1.EnvVar{
		{
			Name: "NAMESPACE",
			ValueFrom: &corev1.EnvVarSource{
				FieldRef: &corev1.ObjectFieldSelector{
					FieldPath: "metadata.namespace",
				},
			},
		},
		{
			Name: "NODENAME",
			ValueFrom: &corev1.EnvVarSource{
				FieldRef: &corev1.ObjectFieldSelector{
					FieldPath: "spec.nodeName",
				},
			},
		},
	}
	container := corev1.Container{
		Name:            "fetch-mac",
		Image:           "quay.io/rh-nfv-int/cnf-app-mac-fetch:v0.2.0",
		Command:         []string{"/app/main"},
		Args:            args,
		ImagePullPolicy: corev1.PullAlways,
		Env:             env,
	}
	job = &batchv1.Job{
		ObjectMeta: metav1.ObjectMeta{
			Name:      macName.Name,
			Namespace: req.NamespacedName.Namespace,
		},
		Spec: batchv1.JobSpec{
			Template: corev1.PodTemplateSpec{
				Spec: corev1.PodSpec{
					NodeName:      nodeName,
					HostNetwork:   true,
					Containers:    []corev1.Container{container},
					RestartPolicy: corev1.RestartPolicyNever,
				},
			},
		},
	}
	err = r.Create(context.Background(), job)
	return err
}

func getContainerEnvValue(podName, namespace, envName string) (string, error) {
	cmd := []string{
		"sh",
		"-c",
		"echo $" + envName,
	}

	config, err := config.GetConfig()
	if err != nil {
		return "", err
	}
	client, err := kubernetes.NewForConfig(config)
	execReq := client.CoreV1().RESTClient().Post().Resource("pods").Name(podName).
		Namespace(namespace).SubResource("exec")
	option := &corev1.PodExecOptions{
		Command:   cmd,
		Container: "testpmd",
		Stdin:     true,
		Stdout:    true,
		Stderr:    true,
		TTY:       true,
	}
	execReq.VersionedParams(
		option,
		scheme.ParameterCodec,
	)
	exec, err := remotecommand.NewSPDYExecutor(config, "POST", execReq.URL())
	if err != nil {
		return "", err
	}
	var b bytes.Buffer
	err = exec.Stream(remotecommand.StreamOptions{
		Stdin:  os.Stdin,
		Stdout: &b,
		Stderr: os.Stderr,
	})
	if err != nil {
		return "", err
	}
	return string(b.Bytes()), nil
}

func (r *CNFAppMacReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Pod{}).
		Watches(&source.Kind{Type: &corev1.Pod{}}, &handler.EnqueueRequestForObject{}).
		Complete(r)
	//For(&examplecnfv1.CNFAppMac{}).
	//Owns(&corev1.Pod{}).
}
