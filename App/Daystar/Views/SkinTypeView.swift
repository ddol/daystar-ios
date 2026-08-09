import Foundation
import SwiftUI
import daystar_ios

struct SkinTypeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: FitzpatrickType

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(FitzpatrickType.allCases, id: \.rawValue) { type in
                        Button {
                            selection = type
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.displayName)
                                        .font(.body.weight(.semibold))
                                    Text(type.shortDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(thresholdSummary(for: type))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                                Image(systemName: type == selection ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(type == selection ? Color.accentColor : Color.secondary.opacity(0.4))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Fitzpatrick phototype")
                } footer: {
                    Text("Pick the description that best matches how your skin responds to a first strong sun exposure after winter. Stored on this device only. Thresholds shown are erythema estimation ranges, not personal medical thresholds.")
                }
            }
            .navigationTitle("Skin type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func thresholdSummary(for type: FitzpatrickType) -> String {
        let threshold = FitzpatrickThresholds.erythemaThreshold(for: type)
        let low = threshold.lowerBoundJoulesPerSquareMeter / 100
        let high = threshold.upperBoundJoulesPerSquareMeter / 100
        return "\(low.formatted(.number.precision(.fractionLength(0))))–\(high.formatted(.number.precision(.fractionLength(0)))) SED"
    }
}
