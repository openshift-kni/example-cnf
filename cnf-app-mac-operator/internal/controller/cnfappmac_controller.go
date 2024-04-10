/*
Copyright 2024.

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

package controller

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strings"

	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/remotecommand"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/config"

	examplecnfv1 "github.com/openshift-kni/example-cnf/tree/main/cnf-app-mac-operator/api/v1"
)

const MAC_KEYWORD = "mac"

// CNFAppMacReconciler reconciles a CNFAppMac object
type CNFAppMacReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// Structures used for building CNFAppMac CR
type Device struct {
	Mac string `json:"mac,omitempty"`
	Pci string `json:"pci,omitempty"`
}

type Resource struct {
	Name    string   `json:"name,omitempty"`
	Devices []Device `json:"devices,omitempty"`
}

// Structure that summarizes the content from NetStatus
type NetInfo struct {
	Name       string
	Mac        string
	PciAddress string
}

// Structures used for extracting the information from network-status annotation
type Pci struct {
	PciAddress string `json:"pci-address,omitempty"`
}

type DeviceInfo struct {
	Type    string `json:"type,omitempty"`
	Version string `json:"version,omitempty"`
	Pci     Pci    `json:"pci,omitempty"`
}

type NetStatus struct {
	Name       string     `json:"name,omitempty"`
	Mac        string     `json:"mac,omitempty"`
	DeviceInfo DeviceInfo `json:"device-info,omitempty"`
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

//+kubebuilder:rbac:groups=examplecnf.openshift.io,namespace=example-cnf,resources=cnfappmacs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=examplecnf.openshift.io,namespace=example-cnf,resources=cnfappmacs/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=batch,namespace=example-cnf,resources=jobs,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",namespace=example-cnf,resources=pods;pods/exec;pods/log;secrets;configmaps,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=k8s.cni.cncf.io,namespace=example-cnf,resources=network-attachment-definitions,verbs=get;list;watch
//+kubebuilder:rbac:groups=security.openshift.io,namespace=example-cnf,resources=securitycontextconstraints,resourceNames=hostnetwork,verbs=use

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.15.0/pkg/reconcile
func (r *CNFAppMacReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	//ctx := context.Background()
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

	// Check if the Mac CR is already created for this pod
	macCR := &examplecnfv1.CNFAppMac{}
	err = r.Get(ctx, req.NamespacedName, macCR)
	if err == nil {
		// CNFAppMac CR is found for this pod, skip further processing
		log.Info("CNFAppMac CR is found for this pod, skip further processing")
		return ctrl.Result{}, nil
	} else if !errors.IsNotFound(err) {
		log.Error(err, "Failed to get cr")
		return ctrl.Result{}, err
	}
	podName := req.NamespacedName.Name
	namespace := req.NamespacedName.Namespace

	// Custom object we need to build the CNFAppMac CR
	resInterface := []Resource{}

	// Try to check network annotation
	netStatusesStr, ok := pod.Annotations["k8s.v1.cni.cncf.io/network-status"]
	if !ok {
		log.Info("network-status annotation cannot be found in pod under test, skip further processing")
		return ctrl.Result{}, nil
	} else {
		// Remove line breaks and unmarshal the JSON object that represents the network-status annotation
		netStatusesStr = strings.ReplaceAll(netStatusesStr, "\n", "")
		log.Info("network-status annotation for pod", "raw-net-status", netStatusesStr)

		// Let's suppose, by default, that MACs are present in the network-status annotation
		macUsedInNetStatus := true

		// In OCP 4.12-13, network-status annotation does not include the "mac" attribute for PCI devices,
		// even using mac capability. In that case, we'll have to extract the MAC address directly from the testpmd logs.
		// For that case, the occurence of MAC_KEYWORK must be 0 (or 1 because it appears in ovn-kubernetes interface).
		if strings.Count(netStatusesStr, MAC_KEYWORD) <= 1 {
			macUsedInNetStatus = false
		}

		var netStatuses []NetStatus
		json.Unmarshal([]byte(netStatusesStr), &netStatuses)
		log.Info("Unmarshalled network-status annotation", "unmarshalled-net-status", netStatuses)
		if len(netStatuses) == 0 {
			return ctrl.Result{}, nil
		}

		// Declare the vars that will save the MAC and PCI addresses, in default order
		var macAddresses []string
		var pciAddresses []string

		// Do a first iteration of the netStatuses list to fill in the two lists declared before
		// MAC addresses are only retrieved if macUsedInNetStatus value is true
		for _, netStatus := range netStatuses {

			// Only take the network info if we have a PCI device with a PCI address
			// Discard ovn-kubernetes name
			if netStatus.Name != "ovn-kubernetes" && netStatus.DeviceInfo.Type == "pci" &&
				len(netStatus.DeviceInfo.Pci.PciAddress) > 0 {

				if macUsedInNetStatus {
					macAddresses = append(macAddresses, netStatus.Mac)
					log.Info("Adding item to macAddresses", "item", netStatus.Mac)
				}
				pciAddresses = append(pciAddresses, netStatus.DeviceInfo.Pci.PciAddress)
				log.Info("Adding item to pciAddresses", "item", netStatus.DeviceInfo.Pci.PciAddress)
			}
		}

		// If MACs cannot be extracted from annotations, then extract them from testpmd logs
		if !macUsedInNetStatus {

			macStr, err := getContainerLogValue(podName, namespace)
			if err != nil {
				return ctrl.Result{}, err
			}

			if macStr == "" {
				log.Info("No MAC address retrieved, exiting")
				return ctrl.Result{}, nil
			}

			log.Info("Get mac string from command executed", "mac-string", macStr)

			macs := strings.Split(strings.ReplaceAll(macStr, "\r\n", "\n"), "\n")

			log.Info("Get processed mac string from command executed", "processed-mac-string", macs)

			for _, macAddr := range macs {
				if macAddr != "" {
					macAddresses = append(macAddresses, macAddr)
					log.Info("Adding item to macAddresses", "item", macAddr)
				}
			}

		}

		log.Info("Final status of macAddresses list", "macAddresses", macAddresses)
		log.Info("Final status of pciAddresses list", "pciAddresses", pciAddresses)

		// Booleans that will determine if we have to swap/not swap the order of MAC addresses.
		arePciAddressesSwapped := false
		swapMacAddresses := false
		// Item to start the iteration of the macAddresses list
		macIdx := 0

		// Determine if PCI addresses appear in the order expected by testpmd (from lower to higher)
		// We are currently considering that there will only be two network interfaces.
		if pciAddresses[0] > pciAddresses[1] {
			arePciAddressesSwapped = true
		}

		// MACs have to be swapped if:
		// - MAC annotation exists (macUsedInNetStatus = true) and PCI addresses are swapped (arePciAddressesSwapped = true)
		// - MAC annotation does not exist (macUsedInNetStatus = false) and PCI addresses are not swapped (arePciAddressesSwapped = false)
		if (macUsedInNetStatus && arePciAddressesSwapped) || (!macUsedInNetStatus && !arePciAddressesSwapped) {
			swapMacAddresses = true
			macIdx = len(macAddresses) - 1
		}

		// Translate each NetStatus into NetInfo structure.
		// We will follow the same order than the interfaces that appear listed in the annotations.
		// MAC addresses will be filled according to the order of PCI interfaces that is expected by testpmd.
		// If network already exists, just append MAC and PCI address, else add a new element
		for _, netStatus := range netStatuses {

			// Only take the network info if we have a PCI device with a PCI address
			// Discard ovn-kubernetes name
			if netStatus.Name != "ovn-kubernetes" && netStatus.DeviceInfo.Type == "pci" &&
				len(netStatus.DeviceInfo.Pci.PciAddress) > 0 {

				// MAC address is obtained from macAddresses list, according to the order in which
				// testpmd is handling it.
				macAddress := macAddresses[macIdx]
				if swapMacAddresses {
					macIdx--
				} else {
					macIdx++
				}

				// Extract the data we need
				var netItem = NetInfo{
					Name:       strings.Split(netStatus.Name, "/")[1],
					Mac:        macAddress,
					PciAddress: netStatus.DeviceInfo.Pci.PciAddress,
				}
				log.Info("Extracted NetInfo item", "net-item", netItem)

				// Create the new Device to be included
				dev := Device{
					Pci: netItem.PciAddress,
					Mac: netItem.Mac,
				}
				log.Info("Device to add", "dev", dev)

				// Check if Resource is already saved in resInterface
				// If that's true, then append MAC and PCI address to it
				netFound := false
				for i := 0; i < len(resInterface) && !netFound; i++ {
					resItem := resInterface[i]
					if resItem.Name == netItem.Name {
						netFound = true
						log.Info("Resource exists, status before updating it", "res-before", resInterface[i])

						// Extract current Device list and append the new Device
						currentDevs := resItem.Devices
						currentDevs = append(currentDevs, dev)

						// Let's build a new Resource object to replace the current one
						res := Resource{
							Name:    netItem.Name,
							Devices: currentDevs,
						}
						resInterface[i] = res
						log.Info("Resource status after updating it", "res-after", resInterface[i])
					}
				}
				// If Resource does not exist yet, append new element to resInterface
				if !netFound {
					log.Info("New Resource to be included in the list")

					devInterface := []Device{}
					devInterface = append(devInterface, dev)

					res := Resource{
						Name:    netItem.Name,
						Devices: devInterface,
					}
					log.Info("Adding Resource to list", "res", res)
					resInterface = append(resInterface, res)
				}
			}
			log.Info("List status after iteration", "list", resInterface)
		}

		err = r.createCR(req, pod.UID, pod.Spec.NodeName, resInterface)
		if err != nil {
			return ctrl.Result{}, err
		}
	}

	return ctrl.Result{}, nil
}

func (r *CNFAppMacReconciler) createCR(req ctrl.Request, uid types.UID, nodename string, resInterface []Resource) error {
	log := r.Log.WithValues("cnfappmac", req.NamespacedName)

	name := req.NamespacedName.Name
	namespace := req.NamespacedName.Namespace
	owners := []interface{}{}
	owner := map[string]interface{}{
		"apiVersion":         "v1",
		"controller":         true,
		"blockOwnerDeletion": false,
		"kind":               "Pod",
		"name":               name,
		"uid":                uid,
	}
	owners = append(owners, owner)

	macCR := &unstructured.Unstructured{
		Object: map[string]interface{}{
			"apiVersion": "examplecnf.openshift.io/v1",
			"kind":       "CNFAppMac",
			"metadata": map[string]interface{}{
				"name":            name,
				"namespace":       namespace,
				"ownerReferences": owners,
			},
			"spec": map[string]interface{}{
				"resources": resInterface,
				"node":      nodename,
				"hostname":  name,
			},
		},
	}
	err := r.Create(context.Background(), macCR)
	log.Info("Created CNFAppMac CR", "cnfappmac-cr", macCR)
	return err
}

func (r *CNFAppMacReconciler) removeCR(req ctrl.Request) {
	ctx := context.Background()
	macCR := &examplecnfv1.CNFAppMac{}
	err := r.Get(ctx, req.NamespacedName, macCR)
	if err == nil {
		r.Delete(ctx, macCR)
	}
}

func getContainerLogValue(podName, namespace string) (string, error) {
	cmd := []string{
		"sh",
		"-c",
		"egrep '^Port [0-9]: ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$' /var/log/testpmd/app.log | sed 's/Port [0-9]: //'",
	}
	return executeCmdOnContainer(cmd, podName, namespace)
}

func executeCmdOnContainer(cmd []string, podName, namespace string) (string, error) {
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

// SetupWithManager sets up the controller with the Manager.
func (r *CNFAppMacReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Pod{}).
		Owns(&corev1.Pod{}).
		Complete(r)
	//For(&examplecnfv1.CNFAppMac{}).
}
