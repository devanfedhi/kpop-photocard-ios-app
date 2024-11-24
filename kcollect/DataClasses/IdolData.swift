//
//  IdolData.swift
//  kcollect
//
//  Created by Devan Fedhi on 19/4/2024.
//

import UIKit

class IdolData: NSObject, Decodable {
    var name: String?
    var group: String?
    
    var secondGroup: String?
    var thirdGroup: String?
    
    //    Defines the mapping between the object (IdolData, property name, group, second group and third group) and the JSON data (Stage Name, Group, Other Group, Former Group)
    private enum IdolKeys: String, CodingKey {
        case name = "Stage Name"
        case group = "Group"
        
        case secondGroup = "Other Group"
        case thirdGroup = "Former Group"
    }
    
    // Decoded the object and obtains the corresponding properties from the object
    required init(from decoder: Decoder) throws {
        
        // Get the root container first
        let rootContainer = try decoder.container(keyedBy: IdolKeys.self)
        
        // Then get the idol information
        name = try rootContainer.decode(String.self, forKey: .name)
        group = try? rootContainer.decode(String.self, forKey: .group)
        
        secondGroup = try? rootContainer.decode(String.self, forKey: .secondGroup)
        thirdGroup = try? rootContainer.decode(String.self, forKey: .thirdGroup)
    }


}
