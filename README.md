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

## Building and running

Requires Xcode 26 or newer. Everything goes through the `Makefile`:

```bash
make run
```

That builds the dev app, boots the iOS Simulator, installs and launches it. Other targets:

| Target | Does |
| --- | --- |
| `make help` | list every target |
| `make doctor` | check toolchain, simulator runtimes and signing identities |
| `make test` | run the offline solar/UV engine tests |
| `make build` | build for the iOS Simulator (ad-hoc signed) |
| `make assets` | redraw the app icon and compile the asset catalog |
| `make sign` / `make verify` | re-sign the built app and inspect the signature |
| `make device TEAM_ID=…` | build for a physical iPhone |
| `make ipa TEAM_ID=…` | export a signed development `.ipa` |
| `make logs` | stream the app's simulator log output |

Useful variables: `DEVICE="iPhone 16 Pro"`, `CONFIG=Release`, `BUNDLE_ID=…`,
`SIGN_IDENTITY=…`. If no simulator runtime is installed, `make bootstrap-sim` downloads one.

The app icon is drawn in code (`Scripts/make-appicon.swift`) rather than checked in as an
opaque binary, so icon changes stay reviewable in diffs.

## Current repository scope

This repository currently contains:

- a SwiftUI iPhone/iPad app target (`App/Daystar`, `Daystar.xcodeproj`)
- standalone Swift domain engine modules (no SwiftUI dependency)
- offline city database and search
- solar position/events + irradiance model
- UV dose and burn-time estimation model
- unit tests for key city/date scenarios, including absolute-magnitude checks
- project documentation (`ARCHITECTURE.md`, `SCIENCE.md`, `PRIVACY.md`)

## Burn feature merge bar

For burn-time related changes, **updating `SCIENCE.md` is required** (assumptions, ranges, and citations).

WHO's Standard Erythema Dose baseline (1 SED = 100 J/m² erythemally weighted UV) is used as the physical foundation.
