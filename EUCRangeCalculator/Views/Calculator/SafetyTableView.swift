import SwiftUI

/// Distances reachable while keeping a given % of battery in reserve.
/// All values use the effective Wh/km at the selected cruise speed.
struct SafetyTableView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("calc.safety_table")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(String(localized: "common.at")) \(Int(viewModel.cruiseSpeed)) km/h")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricTile(
                    titleKey: "calc.margin_50",
                    value: String(format: "%.1f", viewModel.distanceForRemainingMargin(50)),
                    unit: "km"
                )
                MetricTile(
                    titleKey: "calc.margin_40",
                    value: String(format: "%.1f", viewModel.distanceForRemainingMargin(40)),
                    unit: "km"
                )
                MetricTile(
                    titleKey: "calc.margin_30",
                    value: String(format: "%.1f", viewModel.distanceForRemainingMargin(30)),
                    unit: "km"
                )
                MetricTile(
                    titleKey: "calc.margin_20",
                    value: String(format: "%.1f", viewModel.distanceForRemainingMargin(20)),
                    unit: "km"
                )
            }

            // Theoretical 0% spans full width
            MetricTile(
                titleKey: "calc.margin_0",
                value: String(format: "%.1f", viewModel.theoreticalRange),
                unit: "km"
            )
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
