import SwiftUI
import daystar_ios

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var showingCityPicker = false
    @State private var showingSkinType = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HeroCard(reading: model.reading, isScrubbing: model.isScrubbing)
                    DayCurveView()
                    ExposureCard(reading: model.reading, model: model)
                    EventsCard(reading: model.reading)
                    ModeledDisclaimer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(BackgroundGradient(category: model.reading.category))
            .navigationTitle(model.selectedCity.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingCityPicker = true } label: {
                        Label("Change city", systemImage: "globe")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSkinType = true } label: {
                        Label("Skin type", systemImage: "person.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCityPicker) {
                CityPickerView(selection: $model.selectedCity)
            }
            .sheet(isPresented: $showingSkinType) {
                SkinTypeView(selection: $model.skinType)
            }
        }
        .task {
            // Keep "now" fresh while the app is foregrounded.
            while !Task.isCancelled {
                model.tick()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }
}

private struct BackgroundGradient: View {
    let category: UVCategory

    var body: some View {
        LinearGradient(
            colors: [category.color.opacity(0.28), .black],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: category)
    }
}

// MARK: - Hero

private struct HeroCard: View {
    let reading: SolarReading
    let isScrubbing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(isScrubbing ? "AT \(Fmt.localClock(reading.date, in: reading.city.location.timeZone).uppercased())" : "NOW")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Fmt.localClock(reading.date, in: reading.city.location.timeZone))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("UV POTENTIAL")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(reading.isDaylight ? reading.category.rawValue : "None")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(reading.isDaylight ? reading.category.color : .secondary)
                    if reading.isDaylight {
                        Text(Fmt.uvIndex(reading.uvIndex))
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(reading.isDaylight ? reading.category.guidance : "The sun is below the horizon.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider().overlay(.white.opacity(0.15))

            HStack(spacing: 0) {
                Metric(
                    label: "Solar intensity",
                    value: Fmt.wattsPerSquareMeter(reading.irradiance.globalHorizontal.wattsPerSquareMeter)
                )
                Metric(label: "Sun altitude", value: Fmt.degrees(reading.position.elevationDegrees))
                Metric(label: "Azimuth", value: Fmt.degrees(reading.position.azimuthDegrees))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct Metric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Exposure

private struct ExposureCard: View {
    let reading: SolarReading
    let model: AppModel

    var body: some View {
        Card(title: "Estimated unprotected exposure", systemImage: "timer") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(Fmt.burnRange(reading.burn))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(reading.burn == nil ? .secondary : reading.category.color)
                    Spacer()
                    Text(model.skinType.displayName)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.1), in: Capsule())
                }

                Text(reading.burn == nil
                     ? "No meaningful burn risk at this sun angle."
                     : "Estimated time to a first erythema (reddening) threshold for \(model.skinType.displayName.lowercased()) skin, with no sunscreen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if reading.isDaylight {
                    Divider().overlay(.white.opacity(0.15))
                    let ahead = model.exposureAhead(minutes: 60)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("If you stay out 1 hour")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(Fmt.standardErythemaDoses(ahead.estimatedErythemalDose))
                                .font(.callout.weight(.semibold).monospacedDigit())
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Total solar energy")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(ahead.totalSolarEnergy.wattHoursPerSquareMeter.formatted(.number.precision(.fractionLength(0)))) Wh/m²")
                                .font(.callout.weight(.semibold).monospacedDigit())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Events

private struct EventsCard: View {
    let reading: SolarReading

    private var timeZone: TimeZone { reading.city.location.timeZone }

    var body: some View {
        Card(title: "Today", systemImage: "sun.horizon") {
            VStack(spacing: 10) {
                Row(label: "Golden hour (morning)",
                    value: Fmt.timeRange(reading.events.goldenHourMorningStart, reading.events.goldenHourMorningEnd, in: timeZone))
                Row(label: "Solar noon", value: Fmt.time(reading.events.solarNoon, in: timeZone))
                Row(label: "Golden hour (evening)",
                    value: Fmt.timeRange(reading.events.goldenHourEveningStart, reading.events.goldenHourEveningEnd, in: timeZone))
                Divider().overlay(.white.opacity(0.15))
                Row(label: "Sunrise", value: Fmt.time(reading.events.sunrise, in: timeZone))
                Row(label: "Sunset", value: Fmt.time(reading.events.sunset, in: timeZone))
                Row(label: "Civil twilight",
                    value: Fmt.timeRange(reading.events.civilDawn, reading.events.civilDusk, in: timeZone))
            }
        }
    }

    private struct Row: View {
        let label: String
        let value: String

        var body: some View {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.subheadline.weight(.semibold).monospacedDigit())
            }
        }
    }
}

private struct ModeledDisclaimer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("MODELED • CLEAR SKY", systemImage: "function")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text("Computed on device from position and time under clear-sky assumptions. Not an observed UV Index, and not medical advice. Cloud, ozone, aerosols, altitude, reflection and individual skin response all change real exposure.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Shared chrome

struct Card<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}
