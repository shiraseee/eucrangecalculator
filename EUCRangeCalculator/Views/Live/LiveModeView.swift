import SwiftUI
import CoreLocation

/// Live mode view: real-time autonomy estimation using GPS speed
/// and rider-provided voltage (or battery percentage).
struct LiveModeView: View {
    @StateObject private var viewModel = LiveModeViewModel()
    @State private var percentValue: Double = 95

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    wheelAndVoltageCard
                    speedCard
                    batteryCard
                    rangeCard

                    trackingControl

                    Text("live.recalibrate_hint")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("live.title")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedWheelId) { _, _ in
                percentValue = viewModel.socPercent
            }
            .onAppear {
                percentValue = viewModel.socPercent
            }
        }
    }

    // MARK: - Wheel + voltage card

    private var wheelAndVoltageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("live.wheel_voltage")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Wheel picker
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
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Input mode segmented control
            Picker("", selection: $viewModel.inputMode) {
                Text("live.input_mode_voltage").tag(LiveModeViewModel.VoltageInputMode.voltage)
                Text("live.input_mode_percent").tag(LiveModeViewModel.VoltageInputMode.percent)
            }
            .pickerStyle(.segmented)

            // Voltage or percent input depending on mode
            HStack(spacing: 8) {
                if viewModel.inputMode == .voltage {
                    TextField("0",
                              value: $viewModel.currentVoltage,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .font(.title3.weight(.medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text("V")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                } else {
                    TextField("95",
                              value: $percentValue,
                              format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .font(.title3.weight(.medium))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: percentValue) { _, newValue in
                            viewModel.setPercent(newValue)
                        }
                    Text("%")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(voltageRangeLabel)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var voltageRangeLabel: String {
        let vMin = viewModel.voltageMin
        let vMax = viewModel.voltageMax
        let format = String(localized: "live.voltage_range")
        return String(format: format, vMin, vMax)
    }

    // MARK: - Speed card

    private var speedCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("live.gps_speed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isTracking {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.hasValidSignal ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(viewModel.hasValidSignal ? "live.gps_live" : "live.gps_no_signal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.0f", viewModel.currentSpeedKmh))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                Text("km/h")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Battery card

    private var batteryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("live.battery_remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f Wh", viewModel.remainingWh))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(String(format: "%.0f%%", viewModel.socPercent))
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(socColor)

            ProgressView(value: max(0, min(1, viewModel.soc)))
                .tint(socColor)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var socColor: Color {
        let pct = viewModel.socPercent
        if pct < 30 { return .red }
        if pct <= 50 { return .orange }
        return .green
    }

    // MARK: - Range card

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("live.range_at_speed")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", viewModel.remainingRange))
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                Text("km")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                MetricTile(
                    titleKey: "live.margin_30",
                    value: String(format: "%.1f", viewModel.rangeMargin30),
                    unit: "km"
                )
                MetricTile(
                    titleKey: "live.live_consumption",
                    value: String(format: "%.1f", viewModel.effectiveWhPerKm),
                    unit: "Wh/km"
                )
                MetricTile(
                    titleKey: "live.motor_load",
                    value: String(format: "%.0f", viewModel.motorLoadPercent),
                    unit: "%"
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

    // MARK: - Tracking control

    @ViewBuilder
    private var trackingControl: some View {
        switch viewModel.authStatus {
        case .denied, .restricted:
            openSettingsButton
        default:
            startStopButton(start: !viewModel.isTracking)
        }
    }

    private func startStopButton(start: Bool) -> some View {
        Button {
            if start {
                viewModel.startTracking()
            } else {
                viewModel.stopTracking()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: start ? "play.fill" : "stop.fill")
                Text(start ? "live.start_tracking" : "live.stop_tracking")
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(start ? Color.accentColor : Color(.systemGray3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var openSettingsButton: some View {
        VStack(spacing: 8) {
            Text("live.permission_denied")
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("live.open_settings")
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

#Preview {
    LiveModeView()
}
