# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased] -

## [0.2.24] - 2025-01-20

- Allow to enable/disable the deployment of the test scripts from outside

## [0.2.23] - 2024-12-27

- Enable reduced mode

## [0.2.22] - 2024-12-12

- Updated OperatorSDK to v1.38.0, kube-rbac-proxy is no longer included
- Updated Kustomize to v5.4.2
- Updated Ansible operator to v1.36.1

## [0.2.21] - 2024-12-11

- Update container image labels

## [0.2.20] - 2024-12-04

- Remove reference to testpmd-lb-operator

## [0.2.19] - 2024-10-22

- Include olm.skipRange annotation

## [0.2.18] - 2024-08-05

- Updated OperatorSDK to v1.36.0
- Updated Kustomize to v5.3.0

## [0.2.17] - 2024-08-01

- Provide updated spec.icon field in config/manifests/bases/testpmd-operator.clusterserviceversion.yaml

## [0.2.16] - 2024-07-31

- Provide required-annotations.yaml file to update CSV annotations in order to pass Preflight's RequiredAnnotations test

## [0.2.15] - 2024-02-15

- Changed skeleton, based on operator-sdk v1.33.0

## [0.2.14] - 2023-01-24

- Remove MAC workaround, since it was just needed for OCP 4.5 and below, which are EOL.

## [0.2.13] - 2023-01-12

- Lifecycle webserver included in container images consumed from testpmd-container-app to cover CNF Certification requirements for liveness, readiness and startup probes

## [0.2.12] - 2023-12-22

- Updated OperatorSDK to v1.33.0
- Updated Kustomize to v5.0.1

## [0.2.11] - 2023-12-04

- Updated OperatorSDK to v1.32.0
- Updated ansible requirements
  - operator_sdk.util 0.5.0

## [0.2.10] - 2023-06-02

- Updates required for PR/PUSH Github actions

## [0.2.9] - 2021-08-25

- Updated application versions
  - testpmd-container-app-mac v0.2.3

## [0.2.8] - 2021-08-03

- Added support for shift-on-stack vhostuser ports (which does not have sriovnetwork objects)

## [0.2.6-1] - 2021-07-29

- No changes, just aligning all other operators (testpmd-lb, cnf-app-mac, trex)

## [0.2.6] - 2021-06-21

- Add support to disconnected environments (SHA2 digest)
- Update `quay.io/operator-framework/ansible-operator` to `v1.7.2`
