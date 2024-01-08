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

package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"time"

	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"

	examplecnfv1 "github.com/rh-nfv-int/cnf-app-mac-operator/api/v1"
	"github.com/rh-nfv-int/cnf-app-mac-operator/controllers"
	// +kubebuilder:scaffold:imports
)

const (
  MAX_RETRIES_WEBSERVER_CHECK = 50
)

var (
	scheme   = runtime.NewScheme()
	setupLog = ctrl.Log.WithName("setup")
)

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))

	utilruntime.Must(examplecnfv1.AddToScheme(scheme))
	// +kubebuilder:scaffold:scheme
}

func setLifecycleWebServer() {
	setupLog.Info("configure webserver")

	// Liveness Probe handler
	http.HandleFunc("/healthz", func(rw http.ResponseWriter, r *http.Request) {
		setupLog.Info("query received to check liveness")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})
	// Readiness Probe handler
	http.HandleFunc("/readyz", func(rw http.ResponseWriter, r *http.Request) {
		setupLog.Info("query received to check readiness")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})
	// Startup Probe handler
	http.HandleFunc("/startz", func(rw http.ResponseWriter, r *http.Request) {
		setupLog.Info("query received to check startup")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})

	setupLog.Info("try to start webserver")
	// Launch web server on port 8095
	err := http.ListenAndServe(":8095", nil)
	if err != nil {
		setupLog.Error(err, "unable to start webserver")
		os.Exit(1)
	}
}

func waitUntilLifecycleWebServerIsReady() {
	for retries := 0; retries < MAX_RETRIES_WEBSERVER_CHECK; retries++ {
		// Each retry will be made after 100 ms
		time.Sleep(100 * time.Millisecond)

		// Check startup probe for this case
		res, err := http.Get("http://localhost:8095/startz")
		if err != nil {
			setupLog.Error(err, "error making http request")
			os.Exit(1)
		}
		if res.StatusCode == http.StatusOK {
			setupLog.Info("webserver is ready")
			break
		}
	}
}

// getWatchNamespace returns the Namespace the operator should be watching for changes
func getWatchNamespace() (string, error) {
	// WatchNamespaceEnvVar is the constant for env variable WATCH_NAMESPACE
	// which specifies the Namespace to watch.
	// An empty value means the operator is running with cluster scope.
	var watchNamespaceEnvVar = "WATCH_NAMESPACE"

	ns, found := os.LookupEnv(watchNamespaceEnvVar)
	if !found {
		return "", fmt.Errorf("%s must be set", watchNamespaceEnvVar)
	}
	return ns, nil
}

func main() {
	// Start calling the webserver as a goroutine to make it asynchronously, so that it does not affect
	// to the rest of the execution
	go setLifecycleWebServer()

	// We need to wait until the webserver is ready before proceeding with the rest of the configuration
	// This call must be synchronous
	waitUntilLifecycleWebServerIsReady()

	var metricsAddr string
	var enableLeaderElection bool
	flag.StringVar(&metricsAddr, "metrics-addr", ":8080", "The address the metric endpoint binds to.")
	flag.BoolVar(&enableLeaderElection, "enable-leader-election", false,
		"Enable leader election for controller manager. "+
			"Enabling this will ensure there is only one active controller manager.")
	flag.Parse()

	ctrl.SetLogger(zap.New(zap.UseDevMode(false)))

	watchNamespace, err := getWatchNamespace()
	if err != nil {
		setupLog.Error(err, "unable to get WatchNamespace, "+
			"the manager will watch and manage resources in all namespaces")
	}

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:             scheme,
		MetricsBindAddress: ":8091",
		Port:               9443,
		LeaderElection:     enableLeaderElection,
		LeaderElectionID:   "34092d78.openshift.io",
		Namespace:          watchNamespace,
	})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}

	if err = (&controllers.CNFAppMacReconciler{
		Client: mgr.GetClient(),
		Log:    ctrl.Log.WithName("controllers").WithName("CNFAppMac"),
		Scheme: mgr.GetScheme(),
	}).SetupWithManager(mgr); err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "CNFAppMac")
		os.Exit(1)
	}
	// +kubebuilder:scaffold:builder

	setupLog.Info("starting manager")
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		setupLog.Error(err, "problem running manager")
		os.Exit(1)
	}
}
