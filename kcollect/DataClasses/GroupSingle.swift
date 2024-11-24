//
//  GroupSingle.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation

// This data class is used to store the favourite group. This is just to make it consistent with how favourite idol is stored as another data class: IdolSingleGroup
class GroupSingle: NSObject {
    var name: String
    
    required init(name: String) {
        self.name = name
    }
    
}
