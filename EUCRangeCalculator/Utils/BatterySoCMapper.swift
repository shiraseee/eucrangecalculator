import Foundation

/// Converts between battery voltage and State of Charge (SoC).
///
/// V1 uses a simple linear model: SoC% = (V - V_min) / (V_max - V_min) × 100
/// where V_max is the nominal pack voltage (full) and V_min is 80% of nominal
/// (typical cutoff for li-ion EUC packs).
///
/// The real lithium discharge curve is non-linear (flat plateau in the middle,
/// steeper drop at the end), but the linear approximation is what most wheel
/// firmwares use and is good enough for safety estimation.
enum BatterySoCMapper {

    /// Voltage at 100% charge (= nominal voltage of the architecture).
    static func voltageMax(forNominal v: Double) -> Double { v }

    /// Voltage at cutoff/empty.
    /// Approx. 80% of nominal for EUC li-ion packs (e.g. 100.8V → 80.6V).
    static func voltageMin(forNominal v: Double) -> Double { v * 0.8 }

    /// State of Charge (0.0 = empty, 1.0 = full) from voltage.
    static func soc(currentVoltage: Double, nominalVoltage: Double) -> Double {
        let vMax = voltageMax(forNominal: nominalVoltage)
        let vMin = voltageMin(forNominal: nominalVoltage)
        guard vMax > vMin else { return 0 }
        let v = max(vMin, min(vMax, currentVoltage))
        return (v - vMin) / (vMax - vMin)
    }

    /// Remaining energy in Wh given current voltage and total battery capacity.
    static func remainingWh(currentVoltage: Double, nominalVoltage: Double, batteryWh: Double) -> Double {
        return batteryWh * soc(currentVoltage: currentVoltage, nominalVoltage: nominalVoltage)
    }

    /// Convert a percentage (0-100) to estimated voltage.
    /// Useful when the rider's wheel display shows percent rather than volts.
    static func voltage(forPercent percent: Double, nominalVoltage: Double) -> Double {
        let vMax = voltageMax(forNominal: nominalVoltage)
        let vMin = voltageMin(forNominal: nominalVoltage)
        let p = max(0, min(100, percent)) / 100
        return vMin + (vMax - vMin) * p
    }
}
