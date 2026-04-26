import SwiftUI
import Combine
import CoreLocation

/// State holder for the live tab.
///
/// Combines GPS speed (from LocationManager) with the rider-provided voltage
/// to produce a real-time autonomy estimate.
///
/// The voltage can be entered as an absolute number (e.g. 95.2V) or as a
/// percentage (e.g. 73%) — both modes are supported and re-calibration is
/// allowed at any moment during the ride.
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
        didSet { UserDefaults.standard.set(currentVoltage, forKey: Keys.voltage) }
    }
    @Published var inputMode: VoltageInputMode = .voltage

    // MARK: - Dependencies

    let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()

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
    }

    // MARK: - Selection

    var selectedWheel: WheelModel { WheelModel.find(id: selectedWheelId) }

    func selectWheel(_ wheel: WheelModel) {
        selectedWheelId = wheel.id
        // Sensible default voltage when switching wheels (95% full).
        currentVoltage = wheel.voltage * 0.95
    }

    // MARK: - Battery state

    var voltageMax: Double { selectedWheel.voltageMax }
    var voltageMin: Double { selectedWheel.voltageMin }

    var soc: Double {
        BatterySoCMapper.soc(currentVoltage: currentVoltage, nominalVoltage: selectedWheel.voltage)
    }

    var socPercent: Double { soc * 100 }

    var remainingWh: Double {
        BatterySoCMapper.remainingWh(currentVoltage: currentVoltage,
                                     nominalVoltage: selectedWheel.voltage,
                                     batteryWh: selectedWheel.batteryWh)
    }

    /// Re-calibration: when the rider taps the percent picker, store the
    /// equivalent voltage for that percent.
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

    // MARK: - Tracking control

    func startTracking() { locationManager.startUpdating() }
    func stopTracking() { locationManager.stopUpdating() }
}
