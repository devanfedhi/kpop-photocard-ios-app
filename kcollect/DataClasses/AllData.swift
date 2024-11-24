//
//  AllData.swift
//  kcollect
//
//  Created by Devan Fedhi on 19/4/2024.
//

import UIKit

class AllData: NSObject, Decodable {
    var idols: [IdolData]?
    
//    Defines the mapping between the object (AllData, property idols) and the JSON data (data)
    private enum CodingKeys: String, CodingKey {
        case idols = "data"
    }


}

