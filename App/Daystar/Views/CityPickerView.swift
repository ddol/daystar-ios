import Foundation
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

    /// Only the UV headline is shown per row, so this deliberately stops short of a full
    /// `SolarReading` — solar events and a burn estimate would be computed for every visible
    /// row and then thrown away. `modeledUVIndex` is nil below the horizon, which is also the
    /// night signal.
    private var uvIndex: Double? {
        UVModel.estimate(at: .now, location: city.location).modeledUVIndex
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
                        .fill(uvIndex.map { UVCategory(uvIndex: $0).color } ?? .gray)
                        .frame(width: 7, height: 7)
                    Text(uvIndex.map { "UV \(Fmt.uvIndex($0))" } ?? "night")
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
