# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased] -

## [0.2.18] - 2024-07-31

- Provide required-annotations.yaml file to update CSV annotations in order to pass Preflight's RequiredAnnotations test

## [0.2.17] - 2024-04-16

- Changed scaffolding, this time really based on operator-sdk v1.33.0

## [0.2.16] - 2023-01-12

- Lifecycle webserver included in container images consumed from trex-container-app to cover CNF Certification requirements for liveness, readiness and startup probes

## [0.2.15] - 2023-12-22

- Updated OperatorSDK to v1.33.0
- Updated Kustomize to v5.0.1

## [0.2.14] - 2023-12-04

- Updated OperatorSDK to v1.32.0
- Updated ansible requirements
  - operator_sdk.util 0.5.0

## [0.2.13] - 2023-06-02

- Updates required for PR/PUSH Github actions

## [0.2.12] - 2023-02-01

- Moved from beta-version events.k8s.io/v1beta1 to GA events.k8s.io/v1 because of v1beta1 deprecation in OCP-4.12
  - trex-container-server v0.2.6
  - trex-container-app v0.2.6

## [0.2.9] - 2021-08-25

- Updated ansible requirements
  - community.kubernetes 1.2.1
  - operator_sdk.util 0.2.0
- Updated ansible-operator  to v1.10.0
- Updated application versions
  - trex-container-server v0.2.3
  - trex-container-app v0.2.3
## [0.2.8] - 2021-08-03

- Bump version to align with vhostuser changes on testpmd and cnf-app-mac operators

## [0.2.6-1] - 2021-07-29

- No changes, just aligning all other operators (testpmd, cnf-app-mac, testpmd-lb-operator)

## [0.2.6] - 2021-06-29

- Added support to disconnected environments (SHA2 digest)
- Updated `quay.io/operator-framework/ansible-operator` to `v1.7.2`
- Added watch permissions to cnfappmacs
