# Change Log
All notable changes to this project will be documented in this file.

## [Unreleased] -

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
