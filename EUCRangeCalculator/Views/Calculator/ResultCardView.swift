import SwiftUI

/// Main result card: % battery remaining (big number) + 3 metric tiles
/// (effective Wh/km, energy consumed, real range).
struct ResultCardView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("calc.remaining_after_ride")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(statusLabel)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }

            Text(percentText)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(remainingColor)

            ProgressView(value: clampedRemaining, total: 100)
                .tint(remainingColor)

            HStack(spacing: 8) {
                MetricTile(
                    titleKey: "calc.effective_consumption",
                    value: String(format: "%.1f", viewModel.effectiveWhPerKm),
                    unit: "Wh/km"
                )
                MetricTile(
                    titleKey: "calc.energy_consumed",
                    value: String(format: "%.0f", viewModel.energyConsumed),
                    unit: "Wh"
                )
                MetricTile(
                    titleKey: "calc.real_range",
                    value: String(format: "%.1f", viewModel.theoreticalRange),
                    unit: "km"
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

    private var clampedRemaining: Double {
        max(0, min(100, viewModel.percentRemaining))
    }

    private var percentText: String {
        String(format: "%.1f%%", viewModel.percentRemaining)
    }

    private var remainingColor: Color {
        let pct = viewModel.percentRemaining
        if pct <= 0 { return .red }
        if pct < 30 { return .red }
        if pct <= 50 { return .orange }
        return .green
    }

    private var statusColor: Color { remainingColor }

    private var statusLabel: LocalizedStringKey {
        let pct = viewModel.percentRemaining
        if pct <= 0 { return "status.empty" }
        if pct < 30 { return "status.risky" }
        if pct <= 50 { return "status.low_margin" }
        return "status.ok"
    }
}

/// Reusable small metric tile with label, value, unit.
struct MetricTile: View {
    let titleKey: LocalizedStringKey
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleKey)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.callout.weight(.semibold))
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
