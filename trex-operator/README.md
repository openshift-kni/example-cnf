## How to rebuild trex-operator

1. Build new version of the application container (vx.y.z is currently v0.2.6)

```
trex-container-app]$ bash build.sh app
Successfully tagged quay.io/rh-nfv-int/trex-container-app:vx.y.z
trex-container-app]$ podman push quay.io/rh-nfv-int/trex-container-app:vx.y.z
```

2. Build new version of the server.

```
trex-container-app]$ bash build.sh server
Successfully tagged quay.io/rh-nfv-int/trex-container-server:vx.y.z
trex-container-app]$ podman push quay.io/rh-nfv-int/trex-container-server:vx.y.z
```

3. Rebuild trex-operator va.b.c (va.b.c is currently v0.2.12)

```
trex-operator]$ make operator-all
trex-operator]$ make bundle-all
```
