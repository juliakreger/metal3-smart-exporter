// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
        "log"
        "os/exec"
        "net/http"
)

func metricsHandler(w http.ResponseWriter, req *http.Request) {
        output, err := exec.Command("/bin/sh", "/usr/local/bin/return_smart_info.sh").Output()
        if err != nil {
           log.Print("Error calling command: ", err)
        }
        w.Write(output) 

}

func defaultHandler(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte(`<html>
		<head><title>Smartctl Exporter</title></head>
		<body>
		<h1>Smartutil Exporter</h1>
		<p><a href="/metrics">Metrics</a></p>
		</body>
		</html>`))
}

func main() {
        http.HandleFunc("/", defaultHandler)
        http.HandleFunc("/metrics", metricsHandler)
        err := http.ListenAndServe(":59100", nil)

        if err != nil {
                log.Fatal("Failed to start: ", err)
                return
        }

}
