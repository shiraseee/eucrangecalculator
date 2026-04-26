import SwiftUI
import Combine
import CoreLocation

/// State holder for the live tab.
///
/// Combines GPS speed (from LocationManager) with the rider-provided voltage
/// to produce a real-time autonomy estimate.
///
/// The voltage acts as a *baseline anchor*: once set (or re-typed mid-ride to
/// re-calibrate), the SoC%/remaining Wh decay live as energy is integrated
/// from the GPS samples. Distance and chrono keep running across re-calibrations.
@MainActor
final class LiveModeViewModel: ObservableObject {

    enum VoltageInputMode: String, CaseIterable, Identifiable {
        case voltage, percent
        var id: String { rawValue }
    }

    // MARK: - Persisted state

    @Published var selectedWheelId: String {
        didSet { UserDefaults.standard.set(selectedWheelId, forKey: Keys.wheel) }
    }
    @Published var currentVoltage: Double {
        didSet {
            UserDefaults.standard.set(currentVoltage, forKey: Keys.voltage)
            // Re-calibration: any voltage edit (typed, percent slider, wheel
            // change) resets the energy accumulator so SoC% matches the freshly
            // entered voltage. Distance/chrono keep going on purpose.
            energyUsedWh = 0
        }
    }
    @Published var inputMode: VoltageInputMode = .voltage

    // MARK: - Live trip accumulators

    @Published private(set) var energyUsedWh: Double = 0
    @Published private(set) var distanceTraveledKm: Double = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0

    // MARK: - Dependencies

    let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

    private var sessionStartTime: Date?
    private var lastTickTimestamp: Date?
    private var elapsedTicker: Task<Void, Never>?

    /// Above this gap between GPS ticks, skip integrating (tunnel, app
    /// suspended). Avoids back-filling minutes of fake consumption.
    private let maxIntegrationGapSeconds: TimeInterval = 3
    /// Below this speed, treat as standstill — no consumption, no distance.
    private let standstillThresholdKmh: Double = 0.5

    private enum Keys {
        static let wheel = "live.lastWheelId"
        static let voltage = "live.lastVoltage"
    }

    init() {
        let defaults = UserDefaults.standard

        let storedWheel = defaults.string(forKey: Keys.wheel) ?? WheelModel.allModels[0].id
        self.selectedWheelId = storedWheel

        let storedVoltage = defaults.double(forKey: Keys.voltage)
        let wheel = WheelModel.find(id: storedWheel)
        // Default to 95% of nominal if nothing stored yet.
        self.currentVoltage = storedVoltage > 0 ? storedVoltage : wheel.voltage * 0.95

        // Forward LocationManager changes through this ObservableObject so
        // SwiftUI views observing only the LiveModeViewModel still update.
        locationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Integrate energy + distance from each valid GPS tick.
        locationManager.samplePublisher
            .sink { [weak self] sample in
                self?.handleSample(timestamp: sample.timestamp, speedKmh: sample.speedKmh)
            }
            .store(in: &cancellables)
    }

    // MARK: - Selection

    var selectedWheel: WheelModel { WheelModel.find(id: selectedWheelId) }

    func selectWheel(_ wheel: WheelModel) {
        selectedWheelId = wheel.id
        // Sensible default voltage when switching wheels (95% full).
        // The didSet on currentVoltage will reset energyUsedWh.
        currentVoltage = wheel.voltage * 0.95
    }

    // MARK: - Battery state (decay-aware)

    var voltageMax: Double { selectedWheel.voltageMax }
    var voltageMin: Double { selectedWheel.voltageMin }

    /// Wh available at the last manual calibration (typed voltage / percent).
    var initialWh: Double {
        BatterySoCMapper.remainingWh(currentVoltage: currentVoltage,
                                     nominalVoltage: selectedWheel.voltage,
                                     batteryWh: selectedWheel.batteryWh)
    }

    /// Wh remaining right now, after subtracting integrated consumption.
    var remainingWh: Double {
        max(0, initialWh - energyUsedWh)
    }

    var soc: Double {
        let total = selectedWheel.batteryWh
        return total > 0 ? remainingWh / total : 0
    }

    var socPercent: Double { soc * 100 }

    /// Live "equivalent" voltage matching the decayed SoC. Useful as a hint
    /// next to the input field so the rider can spot drift vs. their wheel.
    var liveEquivalentVoltage: Double {
        BatterySoCMapper.voltage(forPercent: socPercent, nominalVoltage: selectedWheel.voltage)
    }

    /// Re-calibration: when the rider taps the percent picker, store the
    /// equivalent voltage for that percent. Goes through `currentVoltage`'s
    /// didSet, which resets `energyUsedWh` for us.
    func setPercent(_ percent: Double) {
        currentVoltage = BatterySoCMapper.voltage(forPercent: percent, nominalVoltage: selectedWheel.voltage)
    }

    // MARK: - Live values

    var currentSpeedKmh: Double { locationManager.speedKmh }
    var isTracking: Bool { locationManager.isUpdating }
    var hasValidSignal: Bool { locationManager.hasValidSignal }
    var authStatus: CLAuthorizationStatus { locationManager.authorizationStatus }

    /// Effective consumption at the current GPS speed.
    /// Falls back to a small floor speed (1 km/h) to avoid a division-by-zero
    /// look at standstill.
    var effectiveWhPerKm: Double {
        RangeCalculator.effectiveWhPerKm(base: selectedWheel.referenceWhPerKm,
                                         cruiseKmh: max(currentSpeedKmh, 1))
    }

    /// Range remaining at the current speed.
    var remainingRange: Double {
        let eff = effectiveWhPerKm
        return eff > 0 ? remainingWh / eff : 0
    }

    /// Range while keeping 30% margin in reserve.
    var rangeMargin30: Double { remainingRange * 0.7 }

    var averagePowerW: Double {
        effectiveWhPerKm * currentSpeedKmh
    }

    var motorLoadPercent: Double {
        let rated = Double(selectedWheel.motorRatedW)
        return rated > 0 ? (averagePowerW / rated) * 100 : 0
    }

    /// Observed Wh/km since the start of this ride (or last re-calibration of
    /// energyUsedWh). Useful to compare against the model's prediction.
    var averageObservedWhPerKm: Double {
        distanceTraveledKm > 0.01 ? energyUsedWh / distanceTraveledKm : 0
    }

    var averageSpeedKmh: Double {
        elapsedSeconds > 0 ? distanceTraveledKm / (elapsedSeconds / 3600) : 0
    }

    // MARK: - Tracking control

    func startTracking() {
        // Fresh ride — wipe accumulators so chrono/distance/energy start at 0.
        energyUsedWh = 0
        distanceTraveledKm = 0
        elapsedSeconds = 0
        lastTickTimestamp = nil
        sessionStartTime = Date()
        locationManager.startUpdating()
        startElapsedTicker()
    }

    func stopTracking() {
        locationManager.stopUpdating()
        elapsedTicker?.cancel()
        elapsedTicker = nil
        sessionStartTime = nil
        lastTickTimestamp = nil
        energyUsedWh = 0
        distanceTraveledKm = 0
        elapsedSeconds = 0
    }

    // MARK: - Private

    /// Drives the chrono so it ticks every second even when no GPS sample
    /// arrived (standstill, brief signal loss).
    private func startElapsedTicker() {
        elapsedTicker?.cancel()
        elapsedTicker = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, let start = self.sessionStartTime else { continue }
                self.elapsedSeconds = Date().timeIntervalSince(start)
            }
        }
    }

    /// Integrate a single GPS sample into the trip accumulators.
    /// Uses the GPS-reported timestamp (not Date()) so processing latency
    /// doesn't skew dt.
    private func handleSample(timestamp: Date, speedKmh: Double) {
        defer { lastTickTimestamp = timestamp }

        guard let last = lastTickTimestamp else { return }
        let dt = timestamp.timeIntervalSince(last)
        // Skip out-of-range gaps: tunnel, app suspended, clock jitter.
        guard dt > 0, dt <= maxIntegrationGapSeconds else { return }
        // Standstill: don't accumulate (avoids penalizing red lights).
        guard speedKmh > standstillThresholdKmh else { return }

        let dtHours = dt / 3600
        let effWhPerKm = RangeCalculator.effectiveWhPerKm(base: selectedWheel.referenceWhPerKm,
                                                          cruiseKmh: speedKmh)
        energyUsedWh += effWhPerKm * speedKmh * dtHours
        distanceTraveledKm += speedKmh * dtHours
    }
}
