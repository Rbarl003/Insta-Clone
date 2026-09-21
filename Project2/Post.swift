//
//  Post.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import Foundation
import ParseSwift

struct Post: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Custom properties
    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    
    // Location data
    var location: ParseGeoPoint?
    var locationName: String?
    
    // Photo metadata
    var photoCreationDate: Date?
    
    // Optional: Add comments count, likes, etc.
    // var commentsCount: Int?
    // var likesCount: Int?
}
