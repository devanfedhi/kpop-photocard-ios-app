//
//  Idol.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation

// Used during the API fetch and stores the idols name and their corresponding group
class Idol: NSObject {
    var name: String
    var group: Group
    
    required init(name: String, group: Group) {
        self.name = name
        self.group = group
    }
    
}
