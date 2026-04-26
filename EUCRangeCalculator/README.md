# EUC Range Calculator — iOS App

Application iOS native en SwiftUI pour calculer l'autonomie réelle d'une gyroroue, avec un mode calculatrice (planification) et un mode Live (GPS temps réel).

## 📦 Contenu

```
EUCRangeCalculator/
├── EUCRangeCalculatorApp.swift          # Point d'entrée @main
├── ContentView.swift                     # TabView avec 2 onglets
├── Models/
│   └── WheelModel.swift                 # 27 modèles de roues
├── ViewModels/
│   ├── RangeCalculatorViewModel.swift   # État onglet Calculatrice
│   └── LiveModeViewModel.swift          # État onglet Live
├── Utils/
│   ├── RangeCalculator.swift            # Calculs purs (testables)
│   ├── BatterySoCMapper.swift           # Voltage ↔ % charge
│   └── LocationManager.swift            # Wrapper CoreLocation
├── Views/
│   ├── Calculator/                      # 7 vues onglet Calculatrice
│   └── Live/                            # 1 vue onglet Live
└── Resources/
    ├── fr.lproj/Localizable.strings     # Français
    └── en.lproj/Localizable.strings     # Anglais
```

**Total : 18 fichiers Swift** + 2 fichiers de localisation. Aucune dépendance externe.

## 🛠️ Setup dans Xcode

### 1. Créer le projet

1. Ouvrir Xcode → **File → New → Project**
2. Choisir **iOS → App**
3. Configurer :
   - Product Name : `EUCRangeCalculator`
   - Interface : **SwiftUI**
   - Language : **Swift**
   - Storage : **None**
   - Include Tests : optionnel
4. Cible iOS minimum : **iOS 17.0** (pour `NavigationStack`, `String(localized:)` et la syntaxe `onChange` moderne)

### 2. Importer les fichiers

1. **Supprimer** les fichiers générés par défaut `ContentView.swift` et `EUCRangeCalculatorApp.swift` (le projet va les recréer depuis le ZIP).
2. **Glisser-déposer** le contenu du dossier `EUCRangeCalculator/` dans le navigateur de projet Xcode.
3. Dans la dialog d'import :
   - Cocher **Copy items if needed**
   - Cocher **Create groups**
   - Sélectionner ta cible
4. Pour les fichiers `Localizable.strings`, Xcode doit reconnaître les `.lproj`. Si ce n'est pas le cas :
   - Sélectionner le projet → onglet **Info**
   - Sous **Localizations**, ajouter **French** et **English**
   - Pour chaque langue, cocher **Localizable.strings**

### 3. Configurer Info.plist (CRITIQUE pour le mode Live)

Le mode Live utilise CoreLocation. Sans cette clé, l'app **plantera** à la première demande de permission GPS.

1. Sélectionner le projet → cible → onglet **Info**
2. Ajouter une nouvelle clé : **Privacy - Location When In Use Usage Description**
3. Valeur (à adapter selon ton message) :
   - FR : `EUC Range Calculator a besoin de ta localisation pour mesurer ta vitesse en temps réel et calculer ton autonomie restante.`
   - EN : `EUC Range Calculator needs your location to measure your real-time speed and calculate your remaining range.`

Ou directement dans le fichier source :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>EUC Range Calculator a besoin de ta localisation pour mesurer ta vitesse en temps réel et calculer ton autonomie restante.</string>
```

⚠️ **Permission Always non requise** : on a délibérément choisi `When In Use` uniquement (l'utilisateur garde l'app ouverte pendant le ride). Le tracking en arrière-plan est volontairement reporté à une V2.

### 4. Compiler

`Cmd + R`. Les deux onglets devraient apparaître. Sélectionne une roue, change la distance et la vitesse — tout réagit en live.

## 🧮 Modèle physique

### Calculatrice : autonomie selon la vitesse

La conso `Wh/km` annoncée par les constructeurs est généralement valable autour de 30 km/h. À plus haute vitesse, la traînée aérodynamique fait exploser la conso (puissance ∝ v³, donc conso au km ∝ v²).

Formule empirique calibrée sur données communauté EUC :

```
effective_Wh/km = base_Wh/km × (0.6 + 0.4 × (vitesse / 30)²)
```

Validation Sherman S (base 18 Wh/km) :

| Vitesse | Facteur | Wh/km réel | Autonomie 3600 Wh |
|---|---|---|---|
| 25 km/h | 0.88 | 15.8 | 228 km |
| 30 km/h | 1.00 | 18.0 | 200 km (référence) |
| 50 km/h | 1.71 | 30.8 | 117 km |
| 70 km/h | 2.78 | 50.0 | 72 km |

### Live : voltage → % de charge

Mapping linéaire :

```
SoC% = (V_actuel - V_min) / (V_max - V_min) × 100
```

avec `V_max` = tension nominale (plein) et `V_min` = 80% du nominal (vide).

⚠️ La courbe lithium-ion réelle est non-linéaire (plateau au milieu, chute en fin). Le linéaire est une approximation V1 acceptable et c'est ce qu'utilisent la plupart des firmwares de roues.

## 🛞 Ajouter une nouvelle roue

Ouvrir `Models/WheelModel.swift` et ajouter une entrée dans `WheelModel.allModels` :

```swift
WheelModel(id: "ma-nouvelle-roue",         // slug stable, ne JAMAIS le changer
           name: "Ma Nouvelle Roue",
           batteryWh: 2500,
           referenceWhPerKm: 19,
           voltage: 100.8,
           motorRatedW: 3000,
           motorPeakW: 7000,
           category: WheelCategory(fr: "Sport / suspension",
                                   en: "Sport / suspension"))
```

C'est tout. L'UI, la persistance, les overrides — tout fonctionne automatiquement.

## ✅ Persistance (équivalent @AppStorage)

L'app mémorise via `UserDefaults` :

| Clé | Onglet | Type |
|---|---|---|
| `calc.lastWheelId` | Calculatrice | String (slug) |
| `calc.lastDistance` | Calculatrice | Double (km) |
| `calc.lastCruiseSpeed` | Calculatrice | Double (km/h) |
| `live.lastWheelId` | Live | String (slug) |
| `live.lastVoltage` | Live | Double (V) |

Les overrides du mode avancé ne sont **pas persistés** (intentionnel : reset à chaque session).

## 🌐 Localisation

Toutes les chaînes UI sont dans `Localizable.strings`. Le système choisit FR ou EN selon la langue de l'iPhone. Les noms de roues (proper nouns) restent identiques. Les catégories sont stockées en bilingue dans le modèle directement.

## 🧪 Tests recommandés (non inclus)

Le code est structuré pour être testable. `RangeCalculator` et `BatterySoCMapper` sont des `enum` de fonctions pures sans état — idéal pour XCTest. Suggestions :

```swift
func testSpeedFactor30kmh() {
    XCTAssertEqual(RangeCalculator.speedFactor(for: 30), 1.0, accuracy: 0.01)
}

func testShermanS70km40kmh() {
    let energy = RangeCalculator.energyConsumed(distance: 70, baseWhPerKm: 18, cruiseKmh: 40)
    XCTAssertEqual(energy, 1652, accuracy: 1)
}

func testSoCAt100Volts100Nominal() {
    let soc = BatterySoCMapper.soc(currentVoltage: 100.8, nominalVoltage: 100.8)
    XCTAssertEqual(soc, 1.0)
}
```

## 📝 Limites à mentionner dans la fiche App Store

Le modèle aéro ne tient pas compte de :
- la **pente** (côte ↑ +20-30 % conso, descente ↓ régen)
- le **vent** (très impactant > 40 km/h)
- le **poids** du rider (~+1 % Wh/km par +5 kg au-dessus de 80 kg)
- la **température** (-15 % à 0 °C)

Bon argument pour une V2 "trajet réel" payante (in-app purchase) avec ces variables.

## 🚀 Ce qui peut être ajouté en V2

- Apple Watch companion (afficher vitesse + autonomie au poignet)
- Enregistrement de trajets (Core Data / SwiftData)
- Courbe lithium 3-segments pour SoC plus précis
- Mode trajet réel avec pente, vent, poids
- Background tracking (capability + revue Apple)
- Partage de configurations roues entre utilisateurs
- Export des données vers Apple Health / Strava

## 📜 License

Code libre à utiliser, modifier et distribuer pour ton produit commercial. Aucune dépendance externe = aucune contrainte de license tierce.
