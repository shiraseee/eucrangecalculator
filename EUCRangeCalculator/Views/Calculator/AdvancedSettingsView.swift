import SwiftUI

/// Advanced toggle that reveals battery and Wh/km overrides.
/// Useful for riders who know their wheel performs differently from spec
/// (custom battery, different riding style, etc.).
struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel
    var inputFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $viewModel.advancedMode) {
                Text("calc.advanced_mode")
                    .font(.callout.weight(.medium))
            }

            if viewModel.advancedMode {
                HStack(spacing: 8) {
                    OverrideField(
                        labelKey: "calc.override_battery",
                        unit: "Wh",
                        value: Binding(
                            get: { viewModel.overrideBatteryWh ?? viewModel.selectedWheel.batteryWh },
                            set: { viewModel.overrideBatteryWh = $0 }
                        ),
                        inputFocused: inputFocused
                    )
                    OverrideField(
                        labelKey: "calc.override_consumption",
                        unit: "Wh/km",
                        value: Binding(
                            get: { viewModel.overrideWhPerKm ?? viewModel.selectedWheel.referenceWhPerKm },
                            set: { viewModel.overrideWhPerKm = $0 }
                        ),
                        inputFocused: inputFocused
                    )
                }
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

private struct OverrideField: View {
    let labelKey: LocalizedStringKey
    let unit: String
    @Binding var value: Double
    var inputFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(labelKey)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 4) {
                TextField("0",
                          value: $value,
                          format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .focused(inputFocused)
                    .textFieldStyle(.plain)
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
