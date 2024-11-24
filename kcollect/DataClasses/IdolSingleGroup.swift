//
//  IdolSingleGroup.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation

// This data class is used to store the favourite idol. This is so that it is convenient to access the idols group
class IdolSingleGroup: NSObject {
    var name: String
    var group: String
    
    required init(name: String, group: String) {
        self.name = name
        self.group = group
    }
    
}
