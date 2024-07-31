# Change Log

All notable changes to this project will be documented in this file.

## [Unreleased] -

## [0.2.17] - 2024-07-31

- Provide required-annotations.yaml file to update CSV annotations in order to pass Preflight's RequiredAnnotations test

## [0.2.16] - 2024-05-02

- Move container image to UBI

## [0.2.15] - 2024-02-14

- Changed skeleton, based on operator-sdk v1.33.0
- Webserver is not needed anymore since operator-sdk v1.33.0 code includes it natively in the controller-manager

## [0.2.14] - 2024-01-26

- Run webserver from external binary

## [0.2.13] - 2024-01-05

- Implement webserver to handle lifecycle and probe requests

## [0.2.12] - 2023-12-22

- Updated OperatorSDK to v1.33.0
- Updated Kustomize to v5.0.1

## [0.2.11] - 2023-12-04

- Updated OperatorSDK to v1.32.0

## [0.2.10] - 2023-06-02

- Updates required for PR/PUSH Github actions

## [0.2.9] - 2021-08-25

- No changes, just aligning all other operators (testpmd, testpmd-lb, trex)

## [0.2.8] - 2021-08-03

- Added support for vhostuser ports, which does not use sriovnetwork objects

## [0.2.6-1] - 2021-07-29

- No changes, just aligning all other operators (testpmd, testpmd-lb, trex)

## [Unreleased] -

## [0.2.6] - 2021-07-01

- Add support to disconnected environments (SHA2 digest)
