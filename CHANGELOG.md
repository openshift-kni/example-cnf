# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased] -

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
