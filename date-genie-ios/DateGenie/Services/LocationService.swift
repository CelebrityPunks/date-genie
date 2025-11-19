import Foundation
import CoreLocation
import Combine
import MapKit

final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var cityName: String?
    @Published var isLoading = false
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var errorMessage: String?
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }
    
    func requestAuthorization() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func fetchCurrentCity() {
        requestAuthorization()
        isLoading = true
        manager.requestLocation()
    }
    
    private func resolveCity(from location: CLLocation) {
        if #available(iOS 26.0, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else {
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = "Unable to create a reverse geocoding request."
                }
                return
            }
            request.preferredLocale = .autoupdatingCurrent
            request.getMapItems { [weak self] mapItems, error in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.handleModernResult(mapItem: mapItems?.first, error: error)
                }
            }
        } else {
            resolveCityWithLegacyGeocoder(location)
        }
    }

    @available(iOS, introduced: 5.0, deprecated: 26.0, message: "Legacy fallback for devices prior to iOS 26.")
    private func resolveCityWithLegacyGeocoder(_ location: CLLocation) {
        guard #available(iOS 26.0, *) else {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                DispatchQueue.main.async {
                    self?.handleLegacyResult(placemark: placemarks?.first, error: error)
                }
            }
            return
        }
    }
    
    @available(iOS 26.0, *)
    private func handleModernResult(mapItem: MKMapItem?, error: Error?) {
        isLoading = false
        if let error {
            errorMessage = error.localizedDescription
            return
        }
        if let city = mapItem?.addressRepresentations?.cityName
            ?? mapItem?.addressRepresentations?.cityWithContext
            ?? mapItem?.address?.shortAddress
            ?? mapItem?.address?.fullAddress {
            cityName = city
            errorMessage = nil
        } else {
            errorMessage = "Couldn't determine your current city."
        }
    }
    
    private func handleLegacyResult(placemark: CLPlacemark?, error: Error?) {
        isLoading = false
        if let error {
            errorMessage = error.localizedDescription
            return
        }
        if let city = placemark?.locality ?? placemark?.subAdministrativeArea {
            cityName = city
            errorMessage = nil
        } else {
            errorMessage = "Couldn't determine your current city."
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            isLoading = false
            return
        }
        resolveCity(from: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
}
