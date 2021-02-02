Entrypoints
===========
`trex-wrapper` is the default entry point for trex app container image.

Choosing Run Apps
=================
Within trex app, there are multiple entrypoints for running each usecase.
In order to choose a usecase, provide `run_app` with appropriate value in
the container environment, while creating the POD.

`run_app=1` - The default mode, if not provided. Runs TRex with LB mode
with the provided profile file using environment `profile`. If profile
is not provided, the `default.py` profile is used, which is part of the
container app. In order to provide custom profiles, use ConfigMap to
mount the files to a specific directory inside the container and provide
the path of the mounted file inside container as `profile` environment
to the container.

`run_app=2` - Run the app in binary search mode

`run_app=3` - Run the app with default profile with direct mode (no 
loadbalancer). Monitory for mac update CR.
