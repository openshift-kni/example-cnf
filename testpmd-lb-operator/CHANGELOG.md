# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased] -

## [0.2.15] - 2024-07-31

- Provide required-annotations.yaml file to update CSV annotations in order to pass Preflight's RequiredAnnotations test

## [0.2.14] - 2024-02-07

- Changed skeleton, based on operator-sdk v1.33.0

## [0.2.13] - 2024-01-12

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

- Updated ansible requirements
  - community.kubernetes 1.2.1
  - operator_sdk.util 0.2.0
- Updated ansible-operator  to v1.10.0
- Updated application versions
  - testpmd-container-app-testpmd v0.2.3
  - testpmd-container-app-listener v0.2.3

## [0.2.8] - 2021-08-03

- Bump version to align with vhostuser changes on testpmd and cnf-app-mac operators

## [0.2.6-1] - 2021-07-29

- No changes, just aligning all other operators (testpmd, cnf-app-mac, trex)

## [0.2.6] - 2021-07-28

- No changes, just bumping version to align to other operators (testpmd, cnf-app-mac, trex)

## [0.2.5] - 2021-06-29

- Added support to disconnected environments (SHA2 digest)
- Updated `quay.io/operator-framework/ansible-operator` to `v1.7.2`
- Updated application versions
  - testpmd-container-app-testpmd v0.2.2
  - testpmd-container-app-listener v0.2.2
