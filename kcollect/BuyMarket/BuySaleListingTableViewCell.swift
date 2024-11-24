//
//  SaleListingTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 9/5/2024.
//

import UIKit

// This class displays the details of a specific sale listing, nested inside another table view of the buy photocard screen
class BuySaleListingTableViewCell: UITableViewCell {
    
    let SECTION_IDOL = 0
    let SECTION_GROUP = 1
    let SECTION_ALBUM = 2
    let SECTION_PRICE = 3
    let SECTION_LOCATION = 4
    let SECTION_CONDITION = 5
    let SECTION_USER = 6
    
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"
    let CELL_PRICE = "priceCell"
    let CELL_LOCATION = "locationCell"
    let CELL_CONDITION = "conditionCell"
    let CELL_USER = "userCell"
    
    var saleListing: SaleListing?
    
    weak var delegate: LocationUserSelectedDelegate?
    
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

// MARK: Table View Method
extension BuySaleListingTableViewCell: UITableViewDelegate {

}

extension BuySaleListingTableViewCell: UITableViewDataSource {
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
        case SECTION_USER:
            return 1
        default:
            return 0
        }
    }
    

//    Create the content for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        This cell will display the idol of the photocard sale listing
        if indexPath.section == SECTION_IDOL {

            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = saleListing?.photocard.idolName
            
            return idolCell
            
            //        This cell will display the group of the photocard sale listing
        } else if indexPath.section == SECTION_GROUP {
            
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = saleListing?.photocard.groupName
            
            return groupCell
            
            //        This cell will display the album of the photocard sale listing
        } else if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = saleListing?.photocard.albumName
            
            return albumCell
            
            //        This cell will display the price of the photocard sale listing
        } else if indexPath.section == SECTION_PRICE {
            let priceCell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE, for: indexPath)
    
            priceCell.textLabel?.text = "Price:"
            
            priceCell.detailTextLabel?.text = "$\(saleListing!.price)"

            return priceCell
            
            //        This cell will display the location of the photocard sale listing
        } else if indexPath.section == SECTION_LOCATION {
            let locationCell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
    
            locationCell.textLabel?.text = "Location:"
            
            locationCell.detailTextLabel?.text = "\(saleListing!.location.title!)"
            
            return locationCell
            
            //        This cell will display the condition of the photocard sale listing
        } else if indexPath.section == SECTION_CONDITION {
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
            
            //        This cell will display the user of the photocard sale listing
        } else {
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
    
            userCell.textLabel?.text = "User:"
            
            userCell.detailTextLabel?.text = "\(saleListing!.photocard.userName!)"
            
            return userCell
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
//     If the user or location cell is selected, we return the index path since it is needed to obtain the user/location (that is, we allow these cells to be selectable). Otherwise, we return nil so that the user can't select other cells
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_LOCATION {
            return indexPath
        } else if indexPath.section == SECTION_USER {
            return indexPath
        }
        return nil
    }
    
//    If a user/location cell has been selected, we need to inform the buy photocard table view controller of the location/user that has been selected using delegation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_LOCATION {
            guard let location = saleListing?.location else {
                return
            }
            delegate?.locationSelected(location)
        } else if indexPath.section == SECTION_USER {
            
            guard let userUID = saleListing?.photocard.userUID, let userName = saleListing?.photocard.userName else {
                return
            }
            
            let user = User(userUID,userName)
            
            delegate?.userSelected(user)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
