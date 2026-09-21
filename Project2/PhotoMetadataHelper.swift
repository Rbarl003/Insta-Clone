//
//  PhotoMetadataHelper.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import UIKit
import Photos
import CoreLocation
import ImageIO

struct PhotoMetadata {
    var creationDate: Date?
    var location: CLLocation?
    var width: Int?
    var height: Int?
}

class PhotoMetadataHelper {
    
    /// Extract metadata from a PHAsset directly
    /// This is the recommended and most reliable method for photos from the Photos library
    static func extractMetadata(from asset: PHAsset) -> PhotoMetadata {
        var metadata = PhotoMetadata()
        
        // Get creation date
        metadata.creationDate = asset.creationDate
        
        // Get location
        metadata.location = asset.location
        
        // Get dimensions
        metadata.width = asset.pixelWidth
        metadata.height = asset.pixelHeight
        
        print("PhotoMetadataHelper: Extracted metadata from PHAsset")
        if let date = metadata.creationDate {
            print("  Creation date: \(date)")
        }
        if let location = metadata.location {
            print("  Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        print("  Dimensions: \(metadata.width ?? 0)x\(metadata.height ?? 0)")
        
        return metadata
    }
    
    /// Get PHAsset from identifier (useful when working with PHPicker)
    static func getAsset(withLocalIdentifier identifier: String) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return fetchResult.firstObject
    }
}
