import Foundation

/// Bilingual category label for a wheel.
struct WheelCategory: Hashable, Codable {
    let fr: String
    let en: String

    /// Returns the localized string based on the current device language.
    var localized: String {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        return lang == "fr" ? fr : en
    }
}

/// A single EUC wheel with all the static specs needed for autonomy calculations.
///
/// To add a new wheel:
///   1. Pick a stable `id` (slug), this is used as the @AppStorage key.
///   2. Fill in batteryWh, referenceWhPerKm (@30 km/h), voltage (nominal),
///      motorRatedW, motorPeakW, and a bilingual category.
///   3. Append to `WheelModel.allModels`.
struct WheelModel: Identifiable, Hashable, Codable {
    /// Stable slug used as a persistence key. Never change for an existing wheel.
    let id: String
    let name: String
    /// Total battery capacity in watt-hours.
    let batteryWh: Double
    /// Reference consumption at 30 km/h in Wh/km.
    /// Real consumption at other speeds is computed by `RangeCalculator.speedFactor`.
    let referenceWhPerKm: Double
    /// Nominal pack voltage (also used as full-charge voltage).
    let voltage: Double
    /// Continuous motor power in watts.
    let motorRatedW: Int
    /// Peak motor power in watts (instantaneous).
    let motorPeakW: Int
    /// Bilingual category tag.
    let category: WheelCategory

    /// Voltage at 100 percent charge (= nominal voltage).
    var voltageMax: Double { voltage }
    /// Approximate cutoff voltage at empty (~80 percent of nominal for li-ion EUC packs).
    var voltageMin: Double { voltage * 0.8 }

    /// All wheels available in the app.
    /// Specs verified against manufacturer documentation
    /// (eWheels, Voltride, MyKingSong, MyInmotion, KingSong.com,
    /// Alien Rides, Speedy Feet, EUCservice).
    static let allModels: [WheelModel] = [
        // MARK: Veteran / Leaperkim
        WheelModel(id: "veteran-sherman-v2", name: "Veteran Sherman (V2)",
                   batteryWh: 3200, referenceWhPerKm: 17, voltage: 100.8,
                   motorRatedW: 2500, motorPeakW: 5000,
                   category: WheelCategory(fr: "Classique longue autonomie", en: "Classic long range")),

        WheelModel(id: "veteran-sherman-s", name: "Veteran Sherman S",
                   batteryWh: 3600, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 3000, motorPeakW: 7000,
                   category: WheelCategory(fr: "Longue autonomie / suspension", en: "Long range / suspension")),

        WheelModel(id: "veteran-sherman-l", name: "Veteran Sherman L",
                   batteryWh: 3600, referenceWhPerKm: 17, voltage: 100.8,
                   motorRatedW: 3500, motorPeakW: 7500,
                   category: WheelCategory(fr: "Longue autonomie", en: "Long range")),

        WheelModel(id: "veteran-sherman-max", name: "Veteran Sherman Max",
                   batteryWh: 3600, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 2800, motorPeakW: 6500,
                   category: WheelCategory(fr: "Longue autonomie / off-road", en: "Long range / off-road")),

        WheelModel(id: "veteran-patton-s", name: "Veteran Patton S",
                   batteryWh: 2220, referenceWhPerKm: 19, voltage: 126,
                   motorRatedW: 3000, motorPeakW: 7000,
                   category: WheelCategory(fr: "Sport / suspension", en: "Sport / suspension")),

        WheelModel(id: "veteran-lynx", name: "Veteran Lynx",
                   batteryWh: 2700, referenceWhPerKm: 20, voltage: 151.2,
                   motorRatedW: 3200, motorPeakW: 8000,
                   category: WheelCategory(fr: "Off-road / suspension", en: "Off-road / suspension")),

        WheelModel(id: "veteran-abrams", name: "Veteran Abrams",
                   batteryWh: 2700, referenceWhPerKm: 19, voltage: 100.8,
                   motorRatedW: 3500, motorPeakW: 7500,
                   category: WheelCategory(fr: "Cruiser longue autonomie", en: "Long range cruiser")),

        // MARK: Begode / Gotway
        WheelModel(id: "begode-master-v4", name: "Begode Master V4",
                   batteryWh: 2400, referenceWhPerKm: 21, voltage: 134.4,
                   motorRatedW: 3500, motorPeakW: 8000,
                   category: WheelCategory(fr: "Sport / suspension", en: "Sport / suspension")),

        WheelModel(id: "begode-master-pro", name: "Begode Master Pro",
                   batteryWh: 4800, referenceWhPerKm: 22, voltage: 134.4,
                   motorRatedW: 5000, motorPeakW: 12000,
                   category: WheelCategory(fr: "Hyper / longue autonomie", en: "Hyper / long range")),

        WheelModel(id: "begode-ex30", name: "Begode EX30",
                   batteryWh: 3600, referenceWhPerKm: 22, voltage: 134.4,
                   motorRatedW: 4000, motorPeakW: 9000,
                   category: WheelCategory(fr: "Hyper / suspension", en: "Hyper / suspension")),

        WheelModel(id: "begode-t4-pro", name: "Begode T4 Pro",
                   batteryWh: 1800, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 2500, motorPeakW: 6000,
                   category: WheelCategory(fr: "Touring / suspension", en: "Touring / suspension")),

        WheelModel(id: "begode-t4-max", name: "Begode T4 Max",
                   batteryWh: 1800, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 3000, motorPeakW: 7000,
                   category: WheelCategory(fr: "Touring / suspension", en: "Touring / suspension")),

        WheelModel(id: "begode-rs19-ht", name: "Begode RS19 HT",
                   batteryWh: 1800, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 2600, motorPeakW: 6000,
                   category: WheelCategory(fr: "Polyvalent", en: "All-around")),

        WheelModel(id: "begode-mten4", name: "Begode Mten4",
                   batteryWh: 750, referenceWhPerKm: 15, voltage: 84,
                   motorRatedW: 1000, motorPeakW: 2500,
                   category: WheelCategory(fr: "Mini / urbain", en: "Mini / urban")),

        // MARK: Inmotion
        WheelModel(id: "inmotion-v13", name: "Inmotion V13",
                   batteryWh: 3024, referenceWhPerKm: 20, voltage: 126,
                   motorRatedW: 4500, motorPeakW: 10000,
                   category: WheelCategory(fr: "Sport / suspension", en: "Sport / suspension")),

        WheelModel(id: "inmotion-v14-adventure", name: "Inmotion V14 Adventure",
                   batteryWh: 2400, referenceWhPerKm: 21, voltage: 134,
                   motorRatedW: 4000, motorPeakW: 9000,
                   category: WheelCategory(fr: "Off-road / suspension", en: "Off-road / suspension")),

        WheelModel(id: "inmotion-v12-ht", name: "Inmotion V12 HT",
                   batteryWh: 1750, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 2800, motorPeakW: 6500,
                   category: WheelCategory(fr: "Polyvalent", en: "All-around")),

        WheelModel(id: "inmotion-v11y", name: "Inmotion V11Y",
                   batteryWh: 1500, referenceWhPerKm: 18, voltage: 84,
                   motorRatedW: 2500, motorPeakW: 7000,
                   category: WheelCategory(fr: "Suspension légère", en: "Light suspension")),

        WheelModel(id: "inmotion-p6", name: "Inmotion P6",
                   batteryWh: 4200, referenceWhPerKm: 25, voltage: 235.2,
                   motorRatedW: 6000, motorPeakW: 20000,
                   category: WheelCategory(fr: "Ultra / record 235V (SiC)", en: "Ultra / record 235V (SiC)")),

        // MARK: King Song
        WheelModel(id: "kingsong-s18", name: "King Song S18",
                   batteryWh: 1110, referenceWhPerKm: 20, voltage: 84,
                   motorRatedW: 2200, motorPeakW: 4000,
                   category: WheelCategory(fr: "Suspension légère", en: "Light suspension")),

        WheelModel(id: "kingsong-s19", name: "King Song S19",
                   batteryWh: 1776, referenceWhPerKm: 18, voltage: 100.8,
                   motorRatedW: 3500, motorPeakW: 6500,
                   category: WheelCategory(fr: "Suspension", en: "Suspension")),

        WheelModel(id: "kingsong-s19-pro", name: "King Song S19 Pro",
                   batteryWh: 1776, referenceWhPerKm: 19, voltage: 100.8,
                   motorRatedW: 3500, motorPeakW: 6500,
                   category: WheelCategory(fr: "Suspension haute puissance", en: "High-power suspension")),

        WheelModel(id: "kingsong-s22-pro", name: "King Song S22 Pro",
                   batteryWh: 2220, referenceWhPerKm: 19, voltage: 126,
                   motorRatedW: 4000, motorPeakW: 8500,
                   category: WheelCategory(fr: "Sport / suspension", en: "Sport / suspension")),

        WheelModel(id: "kingsong-f18", name: "King Song F18",
                   batteryWh: 2664, referenceWhPerKm: 21, voltage: 151.2,
                   motorRatedW: 5000, motorPeakW: 9000,
                   category: WheelCategory(fr: "Hyper / suspension quad", en: "Hyper / quad suspension")),

        WheelModel(id: "kingsong-f22", name: "King Song F22",
                   batteryWh: 2738, referenceWhPerKm: 22, voltage: 155.4,
                   motorRatedW: 5000, motorPeakW: 10000,
                   category: WheelCategory(fr: "Hyper / haute tension", en: "Hyper / high voltage")),

        WheelModel(id: "kingsong-f22-pro", name: "King Song F22 Pro",
                   batteryWh: 3108, referenceWhPerKm: 23, voltage: 176.4,
                   motorRatedW: 5500, motorPeakW: 12000,
                   category: WheelCategory(fr: "Ultra / haute tension 176V", en: "Ultra / 176V high voltage")),

        // MARK: NOSFET
        WheelModel(id: "nosfet-apex", name: "NOSFET Apex",
                   batteryWh: 2700, referenceWhPerKm: 20.5, voltage: 151.2,
                   motorRatedW: 3200, motorPeakW: 8000,
                   category: WheelCategory(fr: "Sport / haute tension", en: "Sport / high voltage"))
    ]

    /// Find a wheel by its stable id, or return the first as fallback.
    static func find(id: String) -> WheelModel {
        allModels.first(where: { $0.id == id }) ?? allModels[0]
    }
}
