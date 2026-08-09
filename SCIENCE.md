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

`UVExposure` integration is numerical (trapezoidal) over time steps.

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
