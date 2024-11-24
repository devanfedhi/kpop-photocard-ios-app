//
//  BuySaleListingTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This view controller displays the current sale listing that may be bought by the current user, and all of its details
class BuySaleListingTableViewController: UITableViewController {
    
//    When this button is selected, we need to request our data base controller to make the purchase for the current user (buyer). This involves removing the sale listing, removing the photocard from the portoflio of the seller as well as adding the photocard to the portfolio of the buyer
    @IBAction func purchaseButton(_ sender: Any) {
        
        guard let saleListing = saleListing else {
            return
        }
        
//        Purchase the photocard
        databaseController?.purchasePhotocard(saleListing)
        
        navigationController?.popViewController(animated: true)
        
    }
    
    let SECTION_IMAGE = 0
    let SECTION_IDOL = 1
    let SECTION_GROUP = 2
    let SECTION_ALBUM = 3
    let SECTION_PRICE = 4
    let SECTION_LOCATION = 5
    let SECTION_CONDITION = 6
    let SECTION_USER = 7
    let SECTION_DATE = 8
    
    
    let CELL_IMAGE = "imageCell"
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"
    let CELL_PRICE = "priceCell"
    let CELL_LOCATION = "locationCell"
    let CELL_CONDITION = "conditionCell"
    let CELL_USER = "userCell"
    let CELL_DATE = "dateCell"
    
    var saleListing: SaleListing?
    
    weak var delegate: LocationUserSelectedDelegate?
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        self.view.backgroundColor = UIColor(named: "Background")

    }
    
//    MARK: View Controller Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
//        Whenever the user wants to view the location of the sale listings, we need to tell the map view controler of the location of the sale listing, which is stored as the sender of the segue
        if segue.identifier == "showMap" {
            if let location = sender as? LocationAnnotation {
                let destination = segue.destination as! MapViewOnlyController
                
                destination.location = location
        
                
            }
            
            //        Whenever the user wants to view the profile of the user of the sale listings, we need to tell the profile view controller of the user of the sale listing, which is stored as the sender of the segue
        } else if segue.identifier == "showExternalProfile" {
            if let user = sender as? User {
                let destination = segue.destination as! ExternalProfileTableViewController
                
                destination.user = user
                
//               Then we ask our database controller to fetch the required data for their specific profile
                databaseController?.setupExternalProfileListener(user.userUID)
                
            }
            
        }
    }

    // MARK: Table View Mehods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_IMAGE:
            return 1
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
        case SECTION_DATE:
            return 1
        default:
            return 0
        }
    }
    
//    Only the location and user cells should be selectable as they are the only cells users can interact with. This makes the other cells unselectable
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_LOCATION {
            return indexPath
        } else if indexPath.section == SECTION_USER {
            return indexPath
        }
        
        return nil
    }

//    Creates the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        This is the cell for the photo of the photocard sale listing
        if indexPath.section == SECTION_IMAGE {
            let imageCell = tableView.dequeueReusableCell(withIdentifier: CELL_IMAGE, for: indexPath) as! PhotocardImageTableViewCell
            
            guard let photocard = saleListing?.photocard else {
                return imageCell
            }
            
            imageCell.photocardImage.image = photocard.image
            
            return imageCell
            
//            This is the cell for the idol of photocard sale listing
        } else if indexPath.section == SECTION_IDOL {

            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = saleListing?.photocard.idolName
            
            return idolCell
            
            //            This is the cell for the group of photocard sale listing
        } else if indexPath.section == SECTION_GROUP {

            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = saleListing?.photocard.groupName
            
            return groupCell
            
            //            This is the cell for the album of photocard sale listing
        } else if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = saleListing?.photocard.albumName
            
            return albumCell
            
            //            This is the cell for the price of photocard sale listing
        } else if indexPath.section == SECTION_PRICE {
            let priceCell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE, for: indexPath)
    
            priceCell.textLabel?.text = "Price:"
            
            if let photocardPrice = saleListing?.price {
                priceCell.detailTextLabel?.text = "$\(photocardPrice)"
            } else {
                priceCell.detailTextLabel?.text = "N/A"
            }

            return priceCell
            
            //            This is the cell for the location of photocard sale listing
        } else if indexPath.section == SECTION_LOCATION {
            let locationCell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
    
            locationCell.textLabel?.text = "Location:"
            
            locationCell.detailTextLabel?.text = saleListing?.location.title
            
            return locationCell
            
            //            This is the cell for the conidtion of photocard sale listing
        } else if indexPath.section == SECTION_CONDITION  {
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
            
            //            This is the cell for the user of photocard sale listing
        } else if indexPath.section == SECTION_USER{
            let userCell = tableView.dequeueReusableCell(withIdentifier: CELL_USER, for: indexPath)
    
            userCell.textLabel?.text = "User:"
            
            userCell.detailTextLabel?.text = saleListing?.photocard.userName ?? "N/A"
            
            return userCell
            
            //            This is the cell for the date when the photocard sale listing  was made
        } else {
            let dateCell = tableView.dequeueReusableCell(withIdentifier: CELL_DATE, for: indexPath)
            
            dateCell.textLabel?.text = "Date:"
            
            if let date = saleListing?.date {
                dateCell.detailTextLabel?.text = getDateAsString(date: date)
            } else {
                dateCell.detailTextLabel?.text = "N/A"
            }
            
            return dateCell
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 9
    }
    
//    If the user/location cell has been selected, we need to segue to the external profile/map view controller respectively.
    
//    This involves sending across the user and location of the sale listing to the correpsonding view controllers
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_LOCATION {
            guard let location = saleListing?.location else {
                return
            }
            self.performSegue(withIdentifier: "showMap", sender: location)
        } else if indexPath.section == SECTION_USER {
            guard let userUID = saleListing?.photocard.userUID, let userName = saleListing?.photocard.userName else {
                return
            }
            
            let user = User(userUID,userName)
            self.performSegue(withIdentifier: "showExternalProfile", sender: user)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_DATE {
            return "ⓘ Tap to view more details"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "ⓘ Tap 'Purchase' to buy"
        }
        
        return nil
    }
    
//    MARK: Miscellaneous Methods
    
//    Convert a date to a string
    func getDateAsString(date: Date) -> String {

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm:ss"
        

        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }

}
