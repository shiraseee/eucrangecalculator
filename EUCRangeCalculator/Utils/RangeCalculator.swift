import Foundation

/// Pure functions for autonomy calculations.
/// No state, no side effects: easy to unit-test and reuse across both modes.
enum RangeCalculator {

    /// Reference cruise speed at which the published Wh/km values apply.
    static let referenceSpeedKmh: Double = 30

    /// Empirical aero model.
    ///
    /// At low speeds (< 30 km/h), rolling resistance dominates and consumption
    /// is roughly constant. At higher speeds, aerodynamic drag grows as v^3,
    /// so consumption per km grows as v^2.
    ///
    /// Calibrated on EUC community data (eucworld.com, ride logs):
    /// - Sherman S at 30 km/h: ~17 Wh/km (reference, factor = 1.0)
    /// - Sherman S at 50 km/h: ~25-30 Wh/km (factor 1.7)
    /// - Sherman S at 60 km/h: ~35-40 Wh/km (factor 2.2)
    ///
    /// Returns a multiplier in approximately [0.78, 3.4] for speeds in [20, 80] km/h.
    static func speedFactor(for kmh: Double) -> Double {
        let v = max(0, kmh)
        return 0.6 + 0.4 * pow(v / referenceSpeedKmh, 2)
    }

    /// Effective Wh/km at a given cruise speed.
    /// `base` is the reference Wh/km at 30 km/h.
    static func effectiveWhPerKm(base: Double, cruiseKmh: Double) -> Double {
        return base * speedFactor(for: cruiseKmh)
    }

    /// Total energy in Wh consumed for a given distance at a given cruise speed.
    static func energyConsumed(distance: Double, baseWhPerKm: Double, cruiseKmh: Double) -> Double {
        return max(0, distance) * effectiveWhPerKm(base: baseWhPerKm, cruiseKmh: cruiseKmh)
    }

    /// Theoretical range from full battery at a given cruise speed.
    /// Returns 0 if Wh/km is non-positive.
    static func theoreticalRange(batteryWh: Double, baseWhPerKm: Double, cruiseKmh: Double) -> Double {
        let eff = effectiveWhPerKm(base: baseWhPerKm, cruiseKmh: cruiseKmh)
        return eff > 0 ? batteryWh / eff : 0
    }

    /// Average motor power demand at cruise speed.
    /// `Wh/km × km/h = W`
    /// (Wh/km × km/h = Wh/h = W).
    static func averagePowerW(baseWhPerKm: Double, cruiseKmh: Double) -> Double {
        return effectiveWhPerKm(base: baseWhPerKm, cruiseKmh: cruiseKmh) * cruiseKmh
    }

    /// Distance reachable while keeping at least `marginPercent` battery in reserve.
    /// Example: with marginPercent = 30, returns 70% of theoretical range.
    static func distanceForMargin(theoreticalRange: Double, marginPercent: Double) -> Double {
        let safe = max(0, min(100, marginPercent))
        return theoreticalRange * (1 - safe / 100)
    }
}
