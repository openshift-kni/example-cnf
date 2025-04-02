# Utils

Here, you can find some utilities included in Example CNF to extend the functionalities offered by the tool.

- [webserver.go](webserver.go): a Golang-based webserver to implement liveness, readiness and startup probes in the container images offered in [testpmd-container-app](../testpmd-container-app) and [trex-container-app](../trex-container-app) folders. The Makefiles offered in these directories take care of copying the webserver code from the utils directory to each image's directory.
- [required-annotations.yaml](required-annotations.yaml): annotations to be appended to the CSVs to pass Preflight's RequiredAnnotations tests. They are appended automatically thanks to the Makefile tasks from each operator.
- [support-images](support-images): projects where you can find the Dockerfile required to build some of the images used as build images by the Example CNF images. These images can be found on quay.io/rh-nfv-int and they are publicly available, you only need credentials to access quay.io. The images can be built with the following commands (you need to run it in a RHEL host with a valid RHEL subscription to be able to download the packages installed in the images, and you need a valid quay.io credentials to push it to quay.io):

```
# build images
$ cd support-images
$ podman build dpdk -f dpdk/Dockerfile -t "quay.io/rh-nfv-int/dpdk:v0.0.1"
$ podman build ubi8-base-testpmd -f ubi8-base-testpmd/Dockerfile -t "quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1"
$ podman build ubi8-base-trex -f ubi8-base-trex/Dockerfile -t "quay.io/rh-nfv-int/ubi8-base-trex:v0.0.1"
$ podman build ubi9-base-grout -f ubi9-base-grout/Dockerfile -t "quay.io/rh-nfv-int/ubi9-base-grout:v0.0.1"

# push images (to quay.io/rh-nfv-int)
$ podman push quay.io/rh-nfv-int/dpdk:v0.0.1
$ podman push quay.io/rh-nfv-int/ubi8-base-testpmd:v0.0.1
$ podman push quay.io/rh-nfv-int/ubi8-base-trex:v0.0.1
$ podman push quay.io/rh-nfv-int/ubi9-base-grout:v0.0.1
```
