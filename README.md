# daystar-ios

Offline-first native Swift foundation for an iPhone/iPad app focused on:

- solar intensity and sun geometry
- clear-sky UV exposure potential
- estimated unprotected burn-time range (Fitzpatrick I–VI)
- city-first comparison workflows

## Privacy-first core

Solar and exposure calculations happen on your device. Your location does not need to be sent to a server.

No account, analytics SDK, backend, or network connection is required for core calculations.

## Scientific boundaries

The current engine returns **MODELED • CLEAR SKY** values.

It does **not** claim to provide observed UV Index from latitude/longitude/time alone.

A future `UVConditionsProvider` protocol is included to plug in observed/forecast UV and atmospheric inputs later.

## Current repository scope

This repository currently contains:

- standalone Swift domain engine modules (no SwiftUI dependency)
- offline city database and search
- solar position/events + irradiance model
- UV dose and burn-time estimation model
- unit tests for key city/date scenarios
- project documentation (`ARCHITECTURE.md`, `SCIENCE.md`, `PRIVACY.md`)

## Burn feature merge bar

For burn-time related changes, **updating `SCIENCE.md` is required** (assumptions, ranges, and citations).

WHO's Standard Erythema Dose baseline (1 SED = 100 J/m² erythemally weighted UV) is used as the physical foundation.
