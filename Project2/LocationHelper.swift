//
//  LocationHelper.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import Foundation
import CoreLocation

class LocationHelper {
    
    /// Convert coordinates to a readable location string
    static func getLocationName(from location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw NSError(domain: "LocationHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "No location found"])
        }
        
        return formatPlacemark(placemark)
    }
    
    /// Format placemark into a readable string
    private static func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Try to build a location string from available components
        if let name = placemark.name {
            components.append(name)
        }
        
        if let locality = placemark.locality { // City
            if !components.contains(locality) {
                components.append(locality)
            }
        }
        
        if let administrativeArea = placemark.administrativeArea { // State
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        // If we have nothing, try to use subLocality or subAdministrativeArea
        if components.isEmpty {
            if let subLocality = placemark.subLocality {
                components.append(subLocality)
            } else if let subAdministrativeArea = placemark.subAdministrativeArea {
                components.append(subAdministrativeArea)
            }
        }
        
        // Return formatted string or coordinates as fallback
        if components.isEmpty {
            return String(format: "%.4f, %.4f", placemark.location?.coordinate.latitude ?? 0, placemark.location?.coordinate.longitude ?? 0)
        }
        
        return components.joined(separator: ", ")
    }
    
    /// Get a short location name (just city and state)
    static func getShortLocationName(from location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw NSError(domain: "LocationHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "No location found"])
        }
        
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if components.isEmpty {
            if let name = placemark.name {
                return name
            }
            return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
        }
        
        return components.joined(separator: ", ")
    }
}
