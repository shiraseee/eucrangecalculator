import SwiftUI

/// Specs card: 6 tiles showing the wheel's static specs.
struct SpecsCardView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("calc.specs_title")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                MetricTile(titleKey: "calc.battery", value: String(format: "%.0f", viewModel.selectedWheel.batteryWh), unit: "Wh")
                MetricTile(titleKey: "calc.voltage", value: String(format: "%.1f", viewModel.selectedWheel.voltage), unit: "V")
                MetricTile(titleKey: "calc.consumption_ref", value: String(format: "%.1f", viewModel.selectedWheel.referenceWhPerKm), unit: "Wh/km")
                MetricTile(titleKey: "calc.motor_rated", value: "\(viewModel.selectedWheel.motorRatedW)", unit: "W")
                MetricTile(titleKey: "calc.motor_peak", value: "\(viewModel.selectedWheel.motorPeakW)", unit: "W")

                // Category tile (text only, no unit)
                VStack(alignment: .leading, spacing: 4) {
                    Text("calc.category")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(viewModel.selectedWheel.category.localized)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
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
