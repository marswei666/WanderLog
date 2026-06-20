import Combine
import CoreLocation
import MapKit
import SwiftUI

final class LocationManager: NSObject, ObservableObject {

    static let shared = LocationManager()

    @Published var city: String = ""
    @Published var country: String = ""
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating: Bool = false

    private let manager = CLLocationManager()
    private var locateTimeout: DispatchWorkItem?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        print("📍 requestLocation called, status: \(manager.authorizationStatus.rawValue)")
        city = ""
        country = ""
        isLocating = true
        locateTimeout?.cancel()
        let timeout = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.isLocating {
                print("📍 Location request timed out")
                self.isLocating = false
            }
        }
        locateTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            print("📍 Location denied")
            isLocating = false
            locateTimeout?.cancel()
        @unknown default:
            isLocating = false
            locateTimeout?.cancel()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        locateTimeout?.cancel()
        guard let location = locations.first else { return }
        print("📍 Got location: \(location.coordinate)")
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let self, let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.city = placemark.locality ?? ""
                    self.country = placemark.country ?? ""
                    self.coordinate = location.coordinate
                    self.isLocating = false
                    print("📍 City: \(self.city), Country: \(self.country)")
                }
            } else {
                print("📍 CLGeocoder failed: \(error?.localizedDescription ?? "nil"), trying MKLocalSearch")
                self?.fallbackReverseGeocode(location)
            }
        }
    }

    private func fallbackReverseGeocode(_ location: CLLocation) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        MKLocalSearch(request: request).start { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self, let item = response?.mapItems.first else {
                    print("📍 MKLocalSearch also failed: \(error?.localizedDescription ?? "nil")")
                    self?.isLocating = false
                    return
                }
                self.city = item.placemark.locality ?? ""
                self.country = item.placemark.country ?? ""
                self.coordinate = location.coordinate
                self.isLocating = false
                print("📍 MKLocalSearch City: \(self.city), Country: \(self.country)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        locateTimeout?.cancel()
        DispatchQueue.main.async { self.isLocating = false }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Auth changed: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
