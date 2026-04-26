import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = RangeCalculatorViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    DistanceSpeedInputView(viewModel: viewModel, inputFocused: $inputFocused)
                    WheelSelectorView(viewModel: viewModel)
                    ResultCardView(viewModel: viewModel)
                    PowerCardView(viewModel: viewModel)
                    SpecsCardView(viewModel: viewModel)
                    SafetyTableView(viewModel: viewModel)
                    AdvancedSettingsView(viewModel: viewModel, inputFocused: $inputFocused)
                    Text("calc.hint")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.horizontal)
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("calc.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.reset) {
                        Text("common.reset")
                    }
                    .accessibilityLabel(Text("common.reset"))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common.done") { inputFocused = false }
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
}

#Preview {
    CalculatorView()
}
