# CLAUDE.md

Guide pour les agents IA (Claude Code, Cursor, Copilot, etc.) qui travaillent sur ce repo. Lis-le **avant** d'ouvrir un fichier et d'éditer.

## Project at a glance

**EUC Range Calculator** — App iOS SwiftUI native pour calculer l'autonomie d'une gyroroue électrique. Deux modes :
- **Calculatrice** : planifier un trajet (distance + vitesse → autonomie)
- **Live GPS** : suivi en temps réel (GPS + voltage → autonomie restante)

Cible iOS 17+. Aucune dépendance externe. MVVM strict.

## Build & run

```bash
# Pas de CLI build — projet Xcode pur.
open EUCRangeCalculator.xcodeproj
# Cmd + R dans Xcode.
# Tests (si ajoutés plus tard) : Cmd + U.
```

Pas de Cocoapods, SPM, Carthage. **Ne jamais ajouter de dépendance externe** — argument produit explicite (zéro contrainte de license, taille app minimale, démarrage instantané).

## Architecture en une carte

```
App → ContentView (TabView) → CalculatorView | LiveModeView
                                  ↓                ↓
                         RangeCalculatorVM   LiveModeViewModel
                                  ↓                ↓
                              [Utils — pure functions]
                              RangeCalculator
                              BatterySoCMapper
                              LocationManager (CoreLocation)
                                  ↓
                              [Models — value types]
                              WheelModel
```

Règles :
- Les **Views** sont stateless, observent un `@StateObject` ou `@ObservedObject`
- Les **ViewModels** sont `@MainActor` + `ObservableObject`, contiennent l'état UI et les `@Published`
- **Utils** = `enum` namespaces de fonctions pures (jamais de classe avec état dedans)
- **Model** = `struct` Codable/Hashable, source unique de vérité pour les specs roues

## Code style

- **2 onglets** dans la TabView, jamais plus en V1.
- **Cards** : tous les groupes UI sont dans une card avec `cornerRadius: 14`, `border 0.5px Color(.separator)`, `Color(.systemBackground)` en fond.
- **Petites tiles métriques** : `cornerRadius: 10`, fond `Color(.secondarySystemGroupedBackground)`. Pattern réutilisable via `MetricTile` (défini dans `ResultCardView.swift`).
- **Polices** : `.title3.weight(.medium)` pour inputs, `.system(size: 32-48, weight: .semibold, design: .rounded)` pour les big numbers (autonomie, %, vitesse), `.caption` / `.caption2` pour labels.
- **Couleurs sémantiques** :
  - vert (`.green`) : OK
  - orange (`.orange`) : marge faible / charge moteur 50-80%
  - rouge (`.red`) : risque / charge moteur ≥ 80% / batterie < 30%
- **Pas d'emoji** dans le code source ni les commentaires (réservé aux docs Markdown).

## Le truc qu'il ne faut JAMAIS casser

### 1. La formule du speed factor

`Utils/RangeCalculator.swift` contient :

```swift
static func speedFactor(for kmh: Double) -> Double {
    return 0.6 + 0.4 * pow(kmh / referenceSpeedKmh, 2)
}
```

Cette formule est **calibrée empiriquement** sur les retours communauté EUC (eucworld.com, forums, ride logs). Les constantes `0.6` et `0.4` ne sont pas arbitraires :
- À 30 km/h (vitesse de référence des fiches constructeurs) → facteur = 1.0
- À 50 km/h → facteur ≈ 1.71 (corrobore les observations Sherman)
- À 60 km/h → facteur ≈ 2.20 (idem)

**Ne pas modifier** sans nouvelle calibration sur données réelles. Si quelqu'un demande une formule "plus précise", proposer plutôt un mode **trajet réel** en V2 (avec pente, vent, poids) plutôt que de tordre cette formule.

### 2. Les slugs `id` des WheelModel

```swift
WheelModel(id: "veteran-sherman-s", ...)
```

Ces ids sont des **clés de persistance** (`calc.lastWheelId`, `live.lastWheelId` dans UserDefaults). Si tu renommes un slug existant, tous les utilisateurs perdent leur sélection sauvegardée et atterrissent sur la première roue de la liste. **Une fois publié, un slug est immuable**.

Pour ajouter une nouvelle roue, voir la section "Tâches courantes".

### 3. Le mapping voltage → SoC linéaire

`BatterySoCMapper` utilise un mapping linéaire entre `vMin = 0.8 × vNom` (vide) et `vMax = vNom` (plein). C'est volontairement simple :
- Conforme à ce que font les firmwares de roues
- Facile à expliquer à l'utilisateur
- Pas de table de courbe lithium à maintenir par chimie

Une courbe non-linéaire (3-segments, polynomiale, etc.) **est une feature V2**, pas un fix de V1.

## Conventions de persistance

L'app utilise **UserDefaults manuel** via `didSet` plutôt que `@AppStorage` parce que :
- Plus de contrôle sur les valeurs par défaut quand la clé est absente
- `@AppStorage` dans une `ObservableObject` class a des bugs subtils de cycle de vie

Pattern :

```swift
@Published var distance: Double {
    didSet { UserDefaults.standard.set(distance, forKey: Keys.distance) }
}

init() {
    let stored = UserDefaults.standard.double(forKey: Keys.distance)
    self.distance = stored > 0 ? stored : 70  // default fallback
}
```

Clés actuelles (préfixées par mode pour éviter les collisions) :
- `calc.lastWheelId`, `calc.lastDistance`, `calc.lastCruiseSpeed`
- `live.lastWheelId`, `live.lastVoltage`

**Les overrides du mode avancé NE SONT PAS persistés** (intentionnel : reset à chaque session).

## Localisation

Pattern hybride :
- **Strings UI** → `Localizable.strings` (FR + EN), accessible via `Text("key")` ou `String(localized: "key")`
- **Catégories de roues** → bilingues directement dans le model :
  ```swift
  category: WheelCategory(fr: "Sport / suspension", en: "Sport / suspension")
  ```
  résolues via `category.localized` (basé sur `Locale.current.language.languageCode`)

Pourquoi cette dualité : les catégories sont du **contenu** (changeront quand on ajoutera des roues), les strings UI sont du **chrome** (translation faite une fois, gérée par les outils Xcode standards).

## Tâches courantes

### Ajouter une roue

1. Ouvrir `Models/WheelModel.swift`.
2. Ajouter une entrée dans `WheelModel.allModels` avec :
   - **`id`** : slug stable kebab-case (ex. `"begode-blitz"`). **Vérifie qu'il n'existe pas déjà**.
   - **`name`** : nom commercial exact (ne pas localiser, c'est un nom propre).
   - **`batteryWh`** / **`voltage`** : depuis fiches officielles fabricant (eWheels, Voltride, KingSong, Inmotion, etc.). **Pas d'estimation** sur ces deux.
   - **`referenceWhPerKm`** : conso à 30 km/h. Si pas de donnée précise : utiliser 17-18 (long range), 19-21 (sport/suspension), 22-25 (hyper/high voltage), 15-16 (mini).
   - **`motorRatedW`** / **`motorPeakW`** : depuis fiches officielles si possible.
   - **`category`** : objet `WheelCategory(fr:..., en:...)` aligné sur les catégories existantes.
3. Pas besoin de toucher à autre chose — l'UI, la persistance, les overrides fonctionnent automatiquement.

### Modifier une chaîne UI

1. Ajouter / modifier dans `Resources/fr.lproj/Localizable.strings`.
2. Ajouter / modifier dans `Resources/en.lproj/Localizable.strings` (les deux fichiers doivent rester synchronisés sur les clés).
3. Utiliser dans le code : `Text("ma.cle")` (auto-localized) ou `String(localized: "ma.cle")` (pour interpolation).

### Ajouter un calcul dérivé

1. Si c'est une fonction pure → ajouter dans `Utils/RangeCalculator.swift` ou créer un nouveau fichier `Utils/`.
2. Exposer comme computed property dans le ViewModel concerné.
3. Référencer dans la View. **Ne jamais faire le calcul dans la View** (pas de logique métier dans la couche UI).

### Ajouter une vue card dans le calculateur

1. Créer un fichier dans `Views/Calculator/MaNouvelleVue.swift`.
2. Pattern :
   ```swift
   struct MaNouvelleVue: View {
       @ObservedObject var viewModel: RangeCalculatorViewModel
       var body: some View {
           VStack(alignment: .leading, spacing: 12) {
               Text("calc.titre_card").font(.caption).foregroundStyle(.secondary)
               // contenu
           }
           .padding(16)
           .background(Color(.systemBackground))
           .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
               .stroke(Color(.separator), lineWidth: 0.5))
           .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
       }
   }
   ```
3. Insérer dans `CalculatorView.body` à la bonne position.

### Ajouter un test unitaire

Cibler en priorité `RangeCalculator` et `BatterySoCMapper` (fonctions pures, faciles à tester). Le ViewModel peut être testé avec un mocking minimal puisque pas de réseau, pas de Core Data.

```swift
import XCTest
@testable import EUCRangeCalculator

final class RangeCalculatorTests: XCTestCase {
    func test_speedFactor_at30kmh_isOne() {
        XCTAssertEqual(RangeCalculator.speedFactor(for: 30), 1.0, accuracy: 0.001)
    }
}
```

## Pièges connus

### Le mode avancé reset les overrides quand on change de roue

C'est **voulu** (`selectWheel` set `advancedMode = false` et `overrideXxx = nil`). Si un user ajuste les overrides puis change de roue, ses overrides disparaissent. Si on rapporte ça comme bug : **ce n'est pas un bug**, c'est la spec.

### LocationManager `nonisolated` callbacks

Les méthodes du `CLLocationManagerDelegate` sont `nonisolated` et reviennent sur le main thread via `Task { @MainActor in ... }`. **Ne pas retirer le `@MainActor`** sur la classe ni les `Task`. Sinon, race conditions sur les `@Published`.

### iOS 17 onChange syntax

On utilise `.onChange(of: ...) { _, _ in }` (deux paramètres, valeur ancienne et nouvelle). Pour iOS 16 il faut `{ _ in }`. Le projet cible iOS 17 — **ne pas downgrader** sans accord.

### Les % de batterie en mode Live

Quand le user passe du mode "Volts" au mode "%", on met à jour `percentValue` depuis `socPercent`. Le binding du TextField "%" déclenche `setPercent()` qui réécrit `currentVoltage`. C'est un peu indirect, mais ça permet de garder `currentVoltage` comme **source unique de vérité** côté ViewModel. Ne pas refactorer pour stocker un `currentPercent` séparé — ça créerait un état dérivé bidirectionnel piégeux.

## Out of scope (V2 ou jamais)

- Background tracking GPS (capability + revue Apple)
- Bluetooth pairing avec la roue (différenciateur produit : on **n'a pas** besoin de l'API constructeur)
- Apple Watch companion (V2 envisagée)
- Enregistrement de trajets / Core Data / SwiftData
- Courbe lithium réaliste (plateau + chute)
- Ads (le produit est ad-free par design)
- Compte utilisateur / sync iCloud (UserDefaults suffit)
- Mode trajet réel avec pente / vent / poids (V2 payante envisagée)

Si un user demande un de ces trucs, ne pas l'implémenter dans la branche main. Créer une branche `v2-feature-name` et discuter scope.

## Décisions produit à connaître

- **Permission GPS : When-In-Use uniquement.** Pas de Always.
- **Pas de tracking analytics tiers** (Firebase, Amplitude, etc.). Si besoin, utiliser Apple's StoreKit + AppStore Analytics natif.
- **App gratuite** avec potentielle in-app purchase Pro plus tard.
- **Pas de cross-platform** (Android, web). iOS pur.
- **FR + EN suffisent en V1.** ES, IT, DE, ZH-Hans envisageables dès V1.1 si traction (gros marché EUC).

## Si tu hésites

Lis `README.md` pour le setup utilisateur final. Lis ce fichier (`CLAUDE.md`) pour les décisions internes. Si tu vois quelque chose qui semble bizarre dans le code, **demande avant de refactorer** — il y a souvent une raison produit ou physique derrière.
