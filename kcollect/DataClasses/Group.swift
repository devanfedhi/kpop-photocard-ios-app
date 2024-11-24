//
//  Group.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/4/2024.
//

import Foundation

// Used during the API fetch and stores the groups name and all idols within the group
class Group: NSObject {
    var name: String
    var idols: [String: Idol] = [:]
    
    required init(name: String) {
        self.name = name
    
    }
    


}
