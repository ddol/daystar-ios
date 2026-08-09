# Science notes

## Important distinction

This project separates:

- **MODELED • CLEAR SKY** estimates (current offline engine)
- **OBSERVED / FORECAST** UV/weather data (future providers)

Latitude/longitude/time alone do not produce observed UV Index.

## Solar geometry

Solar position uses NOAA-style analytical approximations (equation of time + declination + hour angle), then derives:

- elevation
- azimuth
- zenith

Solar event times are derived from hour-angle solutions at target solar altitude thresholds:

- sunrise/sunset: -0.833°
- civil twilight: -6°
- golden-hour boundaries: +6° (combined with sunrise/sunset)

## Irradiance model

The offline irradiance model is a simple clear-sky approximation:

- extraterrestrial normal irradiance with annual orbital correction
- relative air mass correction (Kasten & Young 1989 form)
- broadband transmittance approximation with optional elevation influence
- direct + diffuse horizontal components

Outputs are modeled irradiance in W/m².

## UV and erythemal dose model

Burn risk is not calculated directly from total visible/solar irradiance.

Instead:

1. estimate erythemally weighted UV irradiance from clear-sky geometry/irradiance
2. integrate dose over time

Dose foundation:

- WHO/ICNIRP convention: **1 Standard Erythema Dose (SED) = 100 J/m²** erythemally weighted UV.
- WHO/ICNIRP convention: **UV Index = erythemal irradiance (W/m²) × 40**.

`UVExposure` integration is numerical (trapezoidal) over time steps.

### Erythemal fraction and its calibration

`UVModel` derives erythemal irradiance as a fraction of modeled broadband global horizontal
irradiance:

```text
E_ery = GHI × k × cos(zenith)^p        k = 2.65e-4,  p = 1.4
```

Two properties of that fraction matter, and both are easy to get wrong:

- **Scale.** Erythemally weighted UV is a very small slice of the broadband shortwave flux.
  At UVI 11 the erythemal irradiance is 0.275 W/m² against a clear-sky GHI near 1100 W/m² —
  a fraction of ~2.5e-4, *not* the few-percent figure that total UVA+UVB would suggest. The
  erythema action spectrum weights UVB most heavily, and UVB is a small part of total UV.
- **Elevation dependence.** The fraction grows with sun elevation, because UVB is attenuated
  by air mass far more strongly than the broadband flux is. A near-flat fraction would
  overstate UV at low sun angles.

`k` and `p` are calibrated against the widely used clear-sky relation
`UVI ≈ 12.5 · cos(zenith)^2.42` (sea level, 300 DU ozone). Resulting modeled clear-sky noon
values:

| Location | Date | Sun elevation | Modeled UVI |
| --- | --- | --- | --- |
| Singapore | equinox | 71.7° | 11.0 |
| Sydney | mid-January | 71.1° | 11.2 |
| San Francisco | June solstice | 69.1° | 10.1 |
| Dublin | June solstice | 55.9° | 7.4 |

Being a clear-sky model, these run slightly high against typical *observed* values, which
include cloud and aerosol attenuation. That bias is intentional and conservative for a
burn-time feature.

Regression tests pin these absolute magnitudes (`PhysicalMagnitudeTests`). Ordering-only
assertions are not sufficient: a uniform scale error preserves every ordering relationship
while making the burn-time output wrong by orders of magnitude.

### Solar event time anchoring

Sunrise/sunset/solar-noon are hour-angle offsets in *minutes*, so they must be anchored to a
UTC instant rather than to minutes past local midnight. A local day containing a DST
transition is 23 or 25 hours long, and anchoring to local midnight shifts every event on that
day by a full hour. Verified against the NOAA solar calculator to within ~1 minute, including
on transition days (`DaylightSavingTests`).

## Fitzpatrick thresholds (estimation ranges)

The model uses Fitzpatrick-type-dependent threshold ranges (J/m² erythemally weighted UV):

- I: 150–200
- II: 200–250
- III: 250–350
- IV: 350–450
- V: 450–600
- VI: 600–1000

These are estimation ranges for conservative burn-time outputs and should not be interpreted as personal medical thresholds.

## Safety language constraints

UI language should prefer:

- “Estimated unprotected burn”

and avoid:

- “safe exposure time”
- guaranteed outcomes

Sunscreen is intentionally excluded from this MVP burn feature.

## Uncertainty and limitations

Actual UV exposure is strongly affected by cloud, ozone, aerosols, altitude, reflections, local shading, and individual skin response.

Therefore all current burn values are **estimates** under clear-sky assumptions.

## References

- NOAA Solar Calculator equations (solar position/equation-of-time approximation)
- Kasten F, Young AT. Revised optical air mass tables and approximation formula. *Applied Optics* (1989).
- World Health Organization / ICNIRP UV guidance documents defining SED as 100 J/m² erythemally weighted UV.
