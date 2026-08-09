import Charts
import SwiftUI
import daystar_ios

struct DayCurveView: View {
    @Environment(AppModel.self) private var model
    @State private var metric: DailyMetric = .relativeUVPotential

    private var timeZone: TimeZone { model.selectedCity.location.timeZone }

    private var points: [DailyCurvePoint] { model.curve(for: metric) }

    var body: some View {
        Card(title: "Across the day", systemImage: "chart.xyaxis.line") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Metric", selection: $metric) {
                    ForEach(DailyMetric.displayOrder) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                calloutHeader

                chart
                    .frame(height: 190)

                Text("Drag across the chart to inspect a time. \(metric.unit).")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var calloutHeader: some View {
        let reading = model.reading
        let value = currentValue
        return HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Fmt.localClock(reading.date, in: timeZone))
                    .font(.title3.weight(.bold).monospacedDigit())
                Text(metric.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(metric.format(value))
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(reading.category.color)
        }
    }

    /// Value of the selected metric at the displayed instant, read off the same curve the
    /// chart draws so the callout and the plotted line can never disagree.
    private var currentValue: Double {
        let target = model.effectiveDate
        guard let nearest = points.min(by: {
            abs($0.date.timeIntervalSince(target)) < abs($1.date.timeIntervalSince(target))
        }) else { return 0 }
        return nearest.value
    }

    private var chart: some View {
        let events = model.reading.events
        let selected = model.effectiveDate

        return Chart {
            ForEach(points, id: \.date) { point in
                AreaMark(x: .value("Time", point.date), y: .value(metric.title, point.value))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [model.reading.category.color.opacity(0.45), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Time", point.date), y: .value(metric.title, point.value))
                    .foregroundStyle(model.reading.category.color)
                    .interpolationMethod(.catmullRom)
            }

            if let sunrise = events.sunrise {
                RuleMark(x: .value("Sunrise", sunrise))
                    .foregroundStyle(.white.opacity(0.25))
                    .lineStyle(.init(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("rise").font(.system(size: 9)).foregroundStyle(.tertiary)
                    }
            }
            if let sunset = events.sunset {
                RuleMark(x: .value("Sunset", sunset))
                    .foregroundStyle(.white.opacity(0.25))
                    .lineStyle(.init(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("set").font(.system(size: 9)).foregroundStyle(.tertiary)
                    }
            }

            RuleMark(x: .value("Selected", selected))
                .foregroundStyle(.white.opacity(0.7))
                .lineStyle(.init(lineWidth: 1.5))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel(format: .dateTime.hour(), centered: false)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel()
            }
        }
        .chartXScale(domain: dayDomain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = drag.location.x - geometry[plotFrame].origin.x
                                guard let date: Date = proxy.value(atX: x) else { return }
                                model.scrubbedDate = min(max(date, dayDomain.lowerBound), dayDomain.upperBound)
                            }
                            .onEnded { _ in model.scrubbedDate = nil }
                    )
            }
        }
        .chartLegend(.hidden)
    }

    private var dayDomain: ClosedRange<Date> {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: model.effectiveDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return start...end
    }
}
