# Architecture

## Product focus

This project is designed as a world-clock-like solar and UV exposure tracker, not a generic weather app.

## Core module layout

```
Core/
  Astronomy/
    SolarPosition.swift
    SolarEvents.swift
  Irradiance/
    SolarIrradiance.swift
  UV/
    UVModel.swift
    UVExposure.swift
    BurnTimeEstimator.swift
    SkinPhototype.swift
    SkinTypeStore.swift
  Locations/
    Location.swift
    City.swift
    CityDatabase.swift
  Units/
    PhysicalUnits.swift
  Time/
    DailyCurve.swift
```

## Data flow

Astronomy → Irradiance → UV model → Burn-time estimate

1. `SolarCalculator` computes solar geometry from place/time.
2. `IrradianceCalculator` computes clear-sky solar irradiance (W/m²).
3. `UVModel` estimates erythemally weighted irradiance and modeled UV potential.
4. `BurnTimeEstimator` maps Fitzpatrick threshold range to an estimated unprotected burn-time range.

## Offline vs future live data

- Current values are modeled clear-sky estimates.
- `UVConditionsProvider` defines an optional integration point for future observed/forecast UV and atmospheric data.
- Core app utility must remain available without any provider implementation.

## Units

Strongly typed domain wrappers are used for:

- `PowerPerArea` (W/m²)
- `EnergyPerArea` (J/m², Wh/m² conversion)

This avoids raw-`Double` ambiguity in exposure calculations.
