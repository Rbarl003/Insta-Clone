//
//  User.swift
//  Project2
//
//  Created by Ritch Barlatier on 9/20/26.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    // Required by ParseUser
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
    
    // Custom properties (add any additional user properties here)
    // Example: var profileImageFile: ParseFile?
    // Example: var displayName: String?
}
