import SwiftUI

/// Power card: shows how much of the motor's rated power is used at cruise speed.
/// Color-coded: green < 50%, orange 50-80%, red >= 80%.
struct PowerCardView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("calc.motor_load")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(viewModel.motorLoadPercent))% \(String(localized: "calc.of_rated"))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(loadColor)
            }

            HStack(spacing: 8) {
                MetricTile(
                    titleKey: "calc.average_power",
                    value: String(format: "%.0f", viewModel.averagePowerW),
                    unit: "W"
                )
                MetricTile(
                    titleKey: "calc.headroom_to_rated",
                    value: String(format: "%.0f", max(0, viewModel.headroomW)),
                    unit: "W"
                )
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

    private var loadColor: Color {
        let pct = viewModel.motorLoadPercent
        if pct >= 80 { return .red }
        if pct >= 50 { return .orange }
        return .green
    }
}
