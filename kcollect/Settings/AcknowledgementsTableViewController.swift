//
//  AcknowledgementsTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 29/5/2024.
//

import UIKit

// Class to acknowldge any third party libraries used for the app
class AcknowledgementsTableViewController: UITableViewController {
    
    let thirdPartyLibraries =   [[
                                    "Firebase",
                                    """
                                    This app utilises the following third-party code, use of which is hereby acknowledged.
                                    
                                    Firebase (FirebaseAuth, FirebaseFirestore)

                                    Copyright 2017-2024 Google

                                    Licensed under the Apache License, Version 2.0 (the 'License'); you may not use this file except in compliance with the License.
                                    
                                    You may obtain a copy of the License at:
                                    http://www.apache.org/licenses/LICENSE-2.0
                                    
                                    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an 'AS IS' BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
                                    """
                                ],
                                [
                                    "RapidAPI",
                                    """
                                    This app utilises the following API marketpalce, use of which is hereby acknowledged.
                                    
                                    RapidAPI (K-POP API by ThunderAPI)
                                    
                                    The link to the specific API used, K-POP API can be found at:
                                    https://rapidapi.com/thunderapi-thunderapi-default/api/k-pop
                                    
                                    You may read more on the Terms and Service of RapidAPI at:
                                    https://rapidapi.com/terms/
                                    
                                    YOUR USE OF THE SERVICE IS AT YOUR SOLE RISK. THE SERVICE IS PROVIDED ON AN “AS IS” AND “AS AVAILABLE” BASIS. RAPID DISCLAIMS ALL WARRANTIES AND REPRESENTATIONS (EXPRESS OR IMPLIED, ORAL OR WRITTEN) WITH RESPECT TO THESE TERMS, THE SERVICE, ANY OF THE APIS PROVIDED VIA THE SERVICE, ANY API CONTENT/TERMS, ANY USER CONTENT, THE SITE (INCLUDING ANY INFORMATION AND CONTENT MADE AVAILABLE VIA THE SITE AND THE RAPID MATERIALS), THIRD-PARTY INFRASTRUCTURE (AS DEFINED BELOW) AND THIRD-PARTY TRADEMARKS, WHETHER ALLEGED TO ARISE BY OPERATION OF LAW, BY REASON OF CUSTOM OR USAGE IN THE TRADE, BY COURSE OF DEALING OR OTHERWISE, INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR ANY PURPOSE, NON-INFRINGEMENT, AND CONDITION OF TITLE.
                                    
                                    See the TOS page for RapidAPI for more detail.
                                    
                                    
                                    
                                    
                                    """
                                ]]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table view cells should have dynamic height depending on the size of the text
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44.0


    }

    // MARK: Table View Methods

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thirdPartyLibraries.count
    }

    // Create the contents of each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "thirdPartyCell", for: indexPath) as! AcknowledgementsTableViewCell

        cell.libraryLabel.text = self.thirdPartyLibraries[indexPath.row][0]
        cell.libraryText.text = self.thirdPartyLibraries[indexPath.row][1]
        
        // Ensure that the text wraps around if it is too long
        cell.libraryText?.numberOfLines = 0
        cell.libraryText?.lineBreakMode = .byWordWrapping


        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }


}
