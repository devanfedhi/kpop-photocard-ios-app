//
//  User.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation

// Data class to conveniently package a user's UID and their username
class User: NSObject {
    var userUID: String
    var userName: String
    
    required init(_ userUID: String, _ userName: String) {
        self.userUID = userUID
        self.userName = userName
    }
    
    
}
