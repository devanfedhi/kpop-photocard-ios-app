//
//  SaleListingTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 9/5/2024.
//

import UIKit

// This cell holds some sale listing data, which is to be displayed alongside the photocard image on the main sell market. This table view cell basically stores another tableview inside of it
class SaleListingTableViewCell: UITableViewCell {
    
    let SECTION_IDOL = 0
    let SECTION_GROUP = 1
    let SECTION_ALBUM = 2
    let SECTION_PRICE = 3
    let SECTION_LOCATION = 4
    let SECTION_CONDITION = 5
    
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"
    let CELL_PRICE = "priceCell"
    let CELL_LOCATION = "locationCell"
    let CELL_CONDITION = "conditionCell"
    
    var saleListing: SaleListing?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var photocardImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.isScrollEnabled = false

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}

// MARK: Table View Methods

extension SaleListingTableViewCell: UITableViewDelegate {

}

extension SaleListingTableViewCell: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_IDOL:
            return 1
        case SECTION_GROUP:
            return 1
        case SECTION_ALBUM:
            return 1
        case SECTION_PRICE:
            return 1
        case SECTION_LOCATION:
            return 1
        case SECTION_CONDITION:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    // Creates the content for each cell
    
//    Force unwrap is okay here since we know the sale listing must exist as it has been set during the segue to this screen
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This cell just displays the idol of the photocard
        if indexPath.section == SECTION_IDOL {
            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = saleListing?.photocard.idolName
            
            return idolCell
            
            // This cell displays the group of the photocard
        } else if indexPath.section == SECTION_GROUP {
            
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = saleListing?.photocard.groupName
            
            return groupCell
            
//            This cell displays the album of the photocard
        } else if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = saleListing?.photocard.albumName
            
            return albumCell
            
//            This cell displays the price of the photocard
        } else if indexPath.section == SECTION_PRICE {
            let priceCell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE, for: indexPath)
    
            priceCell.textLabel?.text = "Price:"
            
            priceCell.detailTextLabel?.text = "$\(saleListing!.price)"

            return priceCell
            
//            This cell displays the location of the photocard
        } else if indexPath.section == SECTION_LOCATION {
            let locationCell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
    
            locationCell.textLabel?.text = "Location:"
            
            locationCell.detailTextLabel?.text = "\(saleListing!.location.title!)"
            
            return locationCell
            
//            This cell displays the condition of the photocard
        } else {
            let conditionCell = tableView.dequeueReusableCell(withIdentifier: CELL_CONDITION, for: indexPath)
    
            conditionCell.textLabel?.text = "Condition:"
            
            let conditionText: String
            switch saleListing?.condition {
            case 0:
                conditionText = "Poor"
            case 1:
                conditionText = "Fair"
            case 2:
                conditionText = "Excellent"
            case 3:
                conditionText = "Brand New"
            default:
                conditionText = "Poor"
            }
            
            conditionCell.detailTextLabel?.text = conditionText
            
            
            return conditionCell
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
