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
	"fmt"
	"net/http"
	"os"
)

func setLifecycleWebServer() {
	fmt.Println("configure webserver")

	// Liveness Probe handler
	http.HandleFunc("/healthz", func(rw http.ResponseWriter, r *http.Request) {
		fmt.Println("query received to check liveness")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})
	// Readiness Probe handler
	http.HandleFunc("/readyz", func(rw http.ResponseWriter, r *http.Request) {
		fmt.Println("query received to check readiness")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})
	// Startup Probe handler
	http.HandleFunc("/startz", func(rw http.ResponseWriter, r *http.Request) {
		fmt.Println("query received to check startup")
		rw.WriteHeader(200)
		rw.Write([]byte("ok"))
	})

	fmt.Println("try to start webserver")
	// Launch web server on port 8095
	err := http.ListenAndServe(":8095", nil)
	if err != nil {
		fmt.Println(err, "unable to start webserver")
		os.Exit(1)
	}
}

func main() {
	// Call the webserver in a synchronous way.
	setLifecycleWebServer()
}
