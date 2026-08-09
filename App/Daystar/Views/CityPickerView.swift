import SwiftUI
import daystar_ios

struct CityPickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: City
    @State private var query = ""

    private var results: [City] { model.search(query) }

    var body: some View {
        NavigationStack {
            List(results) { city in
                Button {
                    selection = city
                    dismiss()
                } label: {
                    CityRow(city: city, isSelected: city.id == selection.id)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search cities")
            .navigationTitle("Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

private struct CityRow: View {
    let city: City
    let isSelected: Bool

    /// Compared side by side, so each row carries its own live reading.
    private var reading: SolarReading {
        SolarReading.make(city: city, date: .now, skinType: .typeII)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(city.name)
                    .font(.body.weight(.semibold))
                Text([city.region, city.country].compactMap { $0 }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(Fmt.localClock(.now, in: city.location.timeZone))
                    .font(.subheadline.monospacedDigit())
                HStack(spacing: 5) {
                    Circle()
                        .fill(reading.isDaylight ? reading.category.color : .gray)
                        .frame(width: 7, height: 7)
                    Text(reading.isDaylight ? "UV \(Fmt.uvIndex(reading.uvIndex))" : "night")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
