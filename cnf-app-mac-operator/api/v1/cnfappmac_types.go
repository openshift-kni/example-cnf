/*
Copyright 2025.

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

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type Device struct {
	MAC string `json:"mac"`
	IP  string `json:"ip,omitempty"`
	PCI string `json:"pci"`
}

type Resource struct {
	Name    string   `json:"name"`
	Devices []Device `json:"devices"`
}

// CNFAppMacSpec defines the desired state of CNFAppMac
type CNFAppMacSpec struct {
	Hostname  string     `json:"hostname"`
	Node      string     `json:"node"`
	Resources []Resource `json:"resources"`
}

// CNFAppMacStatus defines the observed state of CNFAppMac
type CNFAppMacStatus struct {
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// CNFAppMac is the Schema for the cnfappmacs API
type CNFAppMac struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CNFAppMacSpec   `json:"spec,omitempty"`
	Status CNFAppMacStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// CNFAppMacList contains a list of CNFAppMac
type CNFAppMacList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CNFAppMac `json:"items"`
}

func init() {
	SchemeBuilder.Register(&CNFAppMac{}, &CNFAppMacList{})
}
