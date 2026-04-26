import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = RangeCalculatorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    DistanceSpeedInputView(viewModel: viewModel)
                    WheelSelectorView(viewModel: viewModel)
                    ResultCardView(viewModel: viewModel)
                    PowerCardView(viewModel: viewModel)
                    SpecsCardView(viewModel: viewModel)
                    SafetyTableView(viewModel: viewModel)
                    AdvancedSettingsView(viewModel: viewModel)
                    Text("calc.hint")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("calc.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.reset) {
                        Text("common.reset")
                    }
                    .accessibilityLabel(Text("common.reset"))
                }
            }
        }
    }
}

#Preview {
    CalculatorView()
}
