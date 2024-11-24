//
//  Photocard.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

// Data class for a photocard and all of its properties
class Photocard: NSObject {
    var albumName: String?
    var albumUID: String?
    var date: Date?
    var groupName: String?
    var groupUID: String?
    var idolName: String?
    var idolUID: String?
    var imageFilePath: String?
    var photocardUID: String?
    var userEmail: String?
    var userUID: String?
    var userName: String?
    var image: UIImage?
    var favourite: Bool?
    
    
}
