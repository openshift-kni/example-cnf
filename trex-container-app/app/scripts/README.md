Entrypoints
===========
`trex-wrapper` is the default entry point for trex app container image.

Choosing Run Apps
=================
Within trex app, there are multiple entrypoints for running each use case.
In order to choose a usecase, provide `run_app` with appropriate value in
the container environment, while creating the POD.

`run_app=1` - Run the app with default profile. Monitory for mac update CR.

`run_app=2` - Run the app in binary search mode
