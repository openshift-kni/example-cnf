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
	"context"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	examplecnfv1 "github.com/rh-nfv-int/cnf-app-mac-operator/api/v1"
)

// CNFAppMacReconciler reconciles a CNFAppMac object
type CNFAppMacReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=examplecnf.openshift.io,resources=cnfappmacs,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=examplecnf.openshift.io,resources=cnfappmacs/status,verbs=get;update;patch

func (r *CNFAppMacReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	_ = r.Log.WithValues("cnfappmac", req.NamespacedName)

	// your logic here

	return ctrl.Result{}, nil
}

func (r *CNFAppMacReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&examplecnfv1.CNFAppMac{}).
		Complete(r)
}
