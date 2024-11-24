//
//  SaleListing.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage

// Data class for a SaleListing and all of its properties
class SaleListing: NSObject {
    var photocard: Photocard
    var price: Int
    var location: LocationAnnotation
    var condition: Int
    var date: Date
    
    required init(_ photocard: Photocard, _ price: Int, _ location: LocationAnnotation, _ condition: Int, _ date: Date) {
        self.photocard = photocard
        self.price = price
        self.location = location
        self.condition = condition
        self.date = date
    }
    
    
}
