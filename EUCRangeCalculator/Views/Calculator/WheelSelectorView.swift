import SwiftUI

/// Wheel selector. Uses a Menu picker for compactness with 27 models.
struct WheelSelectorView: View {
    @ObservedObject var viewModel: RangeCalculatorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("calc.wheel")
                .font(.caption)
                .foregroundStyle(.secondary)

            Menu {
                ForEach(WheelModel.allModels) { wheel in
                    Button {
                        viewModel.selectWheel(wheel)
                    } label: {
                        HStack {
                            Text(wheel.name)
                            if wheel.id == viewModel.selectedWheelId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedWheel.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
