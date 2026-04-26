import SwiftUI
import Combine

/// State holder for the calculator tab.
///
/// Persistence: selected wheel id, last distance, and last cruise speed are
/// persisted in UserDefaults so the app reopens where the user left it.
/// (Equivalent to @AppStorage but kept explicit for control over defaults.)
@MainActor
final class RangeCalculatorViewModel: ObservableObject {

    // MARK: - Persisted state

    @Published var selectedWheelId: String {
        didSet { UserDefaults.standard.set(selectedWheelId, forKey: Keys.wheel) }
    }
    @Published var distance: Double {
        didSet { UserDefaults.standard.set(distance, forKey: Keys.distance) }
    }
    @Published var cruiseSpeed: Double {
        didSet { UserDefaults.standard.set(cruiseSpeed, forKey: Keys.cruise) }
    }

    // MARK: - Session-only state (not persisted)

    @Published var advancedMode: Bool = false
    @Published var overrideBatteryWh: Double?
    @Published var overrideWhPerKm: Double?

    private enum Keys {
        static let wheel = "calc.lastWheelId"
        static let distance = "calc.lastDistance"
        static let cruise = "calc.lastCruiseSpeed"
    }

    init() {
        let defaults = UserDefaults.standard

        let storedWheel = defaults.string(forKey: Keys.wheel) ?? WheelModel.allModels[0].id
        self.selectedWheelId = storedWheel

        let storedDistance = defaults.double(forKey: Keys.distance)
        self.distance = storedDistance > 0 ? storedDistance : 70

        let storedCruise = defaults.double(forKey: Keys.cruise)
        self.cruiseSpeed = storedCruise > 0 ? storedCruise : 40
    }

    // MARK: - Selection

    var selectedWheel: WheelModel { WheelModel.find(id: selectedWheelId) }

    func selectWheel(_ wheel: WheelModel) {
        selectedWheelId = wheel.id
        // Reset overrides when switching wheel.
        advancedMode = false
        overrideBatteryWh = nil
        overrideWhPerKm = nil
    }

    // MARK: - Effective values (taking advanced overrides into account)

    var effectiveBatteryWh: Double {
        advancedMode ? (overrideBatteryWh ?? selectedWheel.batteryWh) : selectedWheel.batteryWh
    }

    var effectiveBaseWhPerKm: Double {
        advancedMode ? (overrideWhPerKm ?? selectedWheel.referenceWhPerKm) : selectedWheel.referenceWhPerKm
    }

    /// Real Wh/km after applying the speed factor for the selected cruise speed.
    var effectiveWhPerKm: Double {
        RangeCalculator.effectiveWhPerKm(base: effectiveBaseWhPerKm, cruiseKmh: cruiseSpeed)
    }

    // MARK: - Derived values

    var energyConsumed: Double {
        RangeCalculator.energyConsumed(distance: distance, baseWhPerKm: effectiveBaseWhPerKm, cruiseKmh: cruiseSpeed)
    }

    var percentConsumed: Double {
        effectiveBatteryWh > 0 ? (energyConsumed / effectiveBatteryWh) * 100 : 0
    }

    var percentRemaining: Double { 100 - percentConsumed }

    var theoreticalRange: Double {
        RangeCalculator.theoreticalRange(batteryWh: effectiveBatteryWh, baseWhPerKm: effectiveBaseWhPerKm, cruiseKmh: cruiseSpeed)
    }

    var averagePowerW: Double {
        RangeCalculator.averagePowerW(baseWhPerKm: effectiveBaseWhPerKm, cruiseKmh: cruiseSpeed)
    }

    var motorLoadPercent: Double {
        let rated = Double(selectedWheel.motorRatedW)
        return rated > 0 ? (averagePowerW / rated) * 100 : 0
    }

    var headroomW: Double {
        Double(selectedWheel.motorRatedW) - averagePowerW
    }

    /// Distance reachable with `marginPct`% battery still in reserve.
    func distanceForRemainingMargin(_ marginPct: Double) -> Double {
        RangeCalculator.distanceForMargin(theoreticalRange: theoreticalRange, marginPercent: marginPct)
    }

    // MARK: - Reset

    func reset() {
        distance = 70
        cruiseSpeed = 40
        advancedMode = false
        overrideBatteryWh = nil
        overrideWhPerKm = nil
    }
}
