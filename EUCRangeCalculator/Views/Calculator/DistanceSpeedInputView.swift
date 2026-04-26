import SwiftUI

/// First card: distance and cruise speed (the two primary inputs).
/// Distance comes first per UX decision so the rider sees their target
/// kilometers before anything else.
struct DistanceSpeedInputView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel
    var inputFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 12) {
            // Distance input
            VStack(alignment: .leading, spacing: 6) {
                Text("calc.distance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("70",
                          value: $viewModel.distance,
                          format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .focused(inputFocused)
                    .font(.title3.weight(.medium))
                    .textFieldStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Cruise speed slider
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("calc.cruise_speed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.cruiseSpeed)) km/h")
                        .font(.caption.weight(.medium))
                }
                Slider(value: $viewModel.cruiseSpeed, in: 20...80, step: 5)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
