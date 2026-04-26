import Foundation
import CoreLocation
import Combine

/// Lightweight CoreLocation wrapper that publishes a smoothed speed in km/h.
///
/// Permission strategy: When-In-Use only. The user must keep the app open
/// while riding. Background tracking would require additional capabilities
/// and review attention from Apple, deferred to a future version.
///
/// Speed smoothing: a rolling average over the last `bufferSize` GPS samples
/// is applied to dampen the small jumps that happen when the GPS recovers
/// signal after going through a tunnel, under cover, etc.
@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var speedKmh: Double = 0
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isUpdating: Bool = false
    @Published private(set) var hasLocationError: Bool = false
    @Published private(set) var hasValidSignal: Bool = false

    /// Fires once per valid GPS fix with the device-reported timestamp and the
    /// smoothed speed. Subscribers (e.g. LiveModeViewModel) use this to integrate
    /// energy and distance over real elapsed time, instead of guessing from
    /// instantaneous values.
    let samplePublisher = PassthroughSubject<(timestamp: Date, speedKmh: Double), Never>()

    private let manager = CLLocationManager()
    private var speedBuffer: [Double] = []
    private let bufferSize = 5

    /// Drops `hasValidSignal` to false if no fresh location update arrives
    /// within this window (tunnel, dense cover, lost lock).
    private let signalTimeoutSeconds: TimeInterval = 5
    private var lastValidUpdate: Date?
    private var signalWatchdog: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .otherNavigation
        manager.distanceFilter = 5
        authorizationStatus = manager.authorizationStatus
    }

    /// Request "When In Use" permission.
    /// Make sure NSLocationWhenInUseUsageDescription is set in Info.plist.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Start receiving location updates.
    /// Will trigger a permission request if not yet granted.
    func startUpdating() {
        switch authorizationStatus {
        case .notDetermined:
            requestPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            isUpdating = true
            hasLocationError = false
            startSignalWatchdog()
        case .denied, .restricted:
            hasLocationError = true
        @unknown default:
            break
        }
    }

    /// Stop tracking and reset state.
    func stopUpdating() {
        manager.stopUpdatingLocation()
        isUpdating = false
        hasValidSignal = false
        speedBuffer.removeAll()
        speedKmh = 0
        signalWatchdog?.cancel()
        signalWatchdog = nil
        lastValidUpdate = nil
    }

    /// Polls every second; if the last valid fix is older than the timeout,
    /// flips `hasValidSignal` to false. Without this, a lost GPS lock would
    /// leave the UI showing a stale speed forever.
    private func startSignalWatchdog() {
        signalWatchdog?.cancel()
        signalWatchdog = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if let last = self.lastValidUpdate,
                   Date().timeIntervalSince(last) > self.signalTimeoutSeconds {
                    self.hasValidSignal = false
                }
            }
        }
    }

    /// Average the last few speed samples to smooth out GPS noise.
    private func smoothSpeed(rawMps: Double) -> Double {
        // CoreLocation returns -1 when speed is unknown/invalid.
        let mps = max(0, rawMps)
        let kmh = mps * 3.6
        speedBuffer.append(kmh)
        if speedBuffer.count > bufferSize {
            speedBuffer.removeFirst(speedBuffer.count - bufferSize)
        }
        let sum = speedBuffer.reduce(0, +)
        return sum / Double(speedBuffer.count)
    }
}

extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let raw = last.speed
        let timestamp = last.timestamp
        Task { @MainActor in
            self.speedKmh = self.smoothSpeed(rawMps: raw)
            let valid = raw >= 0
            self.hasValidSignal = valid
            if valid {
                self.lastValidUpdate = Date()
                self.samplePublisher.send((timestamp: timestamp, speedKmh: self.speedKmh))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.hasLocationError = true
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
                self.isUpdating = true
                self.startSignalWatchdog()
            case .denied, .restricted:
                self.hasLocationError = true
                self.isUpdating = false
                self.signalWatchdog?.cancel()
                self.signalWatchdog = nil
            default:
                break
            }
        }
    }
}
