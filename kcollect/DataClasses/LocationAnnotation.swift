//
//  LocationAnnotation.swift
//  LAB07
//
//  Created by Devan Fedhi on 12/5/2024.
//

import UIKit
import MapKit

// Stores the coordinate sof a location as well as its name
class LocationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }

}
