//
//  LocationManager.swift
//  AppleECC
//
//  Created by Apple on 7/2/26.
//


//
//  LocationManager.swift
//  AppleECC
//

import CoreLocation
import Observation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentPlaceName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    // Reverse geocode a coordinate into a readable place name
    func placeName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        let placemark = placemarks?.first
        
        if let neighborhood = placemark?.subLocality {
            return neighborhood
        } else if let city = placemark?.locality {
            return city
        }
        return nil
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
}