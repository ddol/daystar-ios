# Privacy

## Core privacy promise

Solar and exposure calculations happen on-device.

Location does not need to be sent to a remote server for the core experience.

## No tracking in core

This repository does not include:

- account requirements
- analytics/telemetry SDKs
- ad SDKs
- mandatory backend services for core calculations

## Offline operation

The solar/UV modeling engine and city database are usable offline.

## Future network integrations

If future observed/forecast UV providers are added, network use should be optional, explicit, and documented. Core modeled functionality must remain available without network access.
