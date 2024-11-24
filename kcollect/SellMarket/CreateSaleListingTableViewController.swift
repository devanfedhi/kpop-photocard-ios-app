//
//  CreateSaleListingTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit
import MapKit

// This view controller displays the page to create/edit a sale listing
class CreateSaleListingTableViewController: UITableViewController, ConditionChangeDelegate, LocationChangedDelegate {
    
//    The trash button is only visible if the user wants to edit the photocard, not create one
    
    // Once selected, the user will be prompted to verify that they do want to delete the sale listing
    @IBAction func trashButton(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure you want to delete this market listing?", message: "This will delete the sale listing on the market, meaning no person can purchase it. You can create a new sale listing for this photocard later, if you wish.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            guard let saleListing = self.saleListing else {
                return
            }
            
            // If the users confirms, then proceed to delete the sale listing
            self.databaseController?.deleteSaleListing(saleListing)
            self.navigationController?.popViewController(animated: true)
            

            self.tableView.reloadData()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    
    var saleListing: SaleListing?
    var photocard: Photocard?
    
    let SECTION_IMAGE = 0
    let SECTION_IDOL = 1
    let SECTION_GROUP = 2
    let SECTION_ALBUM = 3
    let SECTION_PRICE = 4
    let SECTION_LOCATION = 5
    let SECTION_CONDITION = 6
    
    
    let CELL_IMAGE = "imageCell"
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"
    let CELL_PRICE = "priceCell"
    let CELL_LOCATION = "locationCell"
    let CELL_CONDITION = "conditionCell"
    
    var photocardPrice: Int?
    var photocardLocation: LocationAnnotation?
    var photocardCondition: Int = 0
    
    let MAX_PHOTOCARD_PRICE = 10000
    
    weak var databaseController: DatabaseProtocol?
    
//    This button will create the sale listing using the current details on the page. If there are missing/incorrect details such as the price or location, this will fail and display and error to the user
    @IBAction func saveButton(_ sender: Any) {
        
        guard let photocard = photocard, let photocardPrice = photocardPrice, let photocardLocation = photocardLocation else {
            displayMessage(title: "Error", message: "All fields must be entered before sale listing is made.")
            return
        }
        
        guard photocardPrice < MAX_PHOTOCARD_PRICE, photocardPrice > 0 else {
            displayMessage(title: "Error", message: "Photocard price must be between $0 and $10000")
            return
        }
        
        // This means that price, location and condition are okay. Attempt to add the sale listing
        databaseController?.addSaleListing(photocard,photocardPrice,photocardLocation,photocardCondition)
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        
        self.view.backgroundColor = UIColor(named: "Background")
    }

    // MARK: Table View Methods

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
        default:
            return 0
        }
    }

//    Create the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        This cell just displays the image of the photocard
        if indexPath.section == SECTION_IMAGE {
            let imageCell = tableView.dequeueReusableCell(withIdentifier: CELL_IMAGE, for: indexPath) as! PhotocardImageTableViewCell
            
            guard let photocard = photocard else {
                return imageCell
            }
            
            
            imageCell.photocardImage.image = photocard.image
            
            return imageCell
            
//            This cell displays the idol of the photocard
        } else if indexPath.section == SECTION_IDOL {

            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = photocard?.idolName
            
            return idolCell
            
            //            This cell displays the group of the photocard
        } else if indexPath.section == SECTION_GROUP {
            
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = photocard?.groupName
            
            return groupCell
            
            //            This cell displays the album of the photocard
        } else if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = photocard?.albumName
            
            return albumCell
            
            //            This cell displays the price of the photocard
        } else if indexPath.section == SECTION_PRICE {
            let priceCell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE, for: indexPath)
    
            priceCell.textLabel?.text = "Price:"
            
            if let photocardPrice = photocardPrice {
                priceCell.detailTextLabel?.text = "$\(photocardPrice)"
            } else {
                priceCell.detailTextLabel?.text = "N/A"
            }
            
            return priceCell
            
            //            This cell displays the location title of the photocard
        } else if indexPath.section == SECTION_LOCATION {
            let locationCell = tableView.dequeueReusableCell(withIdentifier: CELL_LOCATION, for: indexPath)
    
            locationCell.textLabel?.text = "Location:"
            
            locationCell.detailTextLabel?.text = photocardLocation?.title ?? "N/A"
            
            return locationCell
            
            //            This cell displays the condition of the photocard, that is the segmented control for the condition
        } else  {
            let conditionCell = tableView.dequeueReusableCell(withIdentifier: CELL_CONDITION, for: indexPath) as! ConditionTableViewCell
            conditionCell.delegate = self
        
            conditionCell.conditionSegmentedControl.selectedSegmentIndex = photocardCondition

            return conditionCell
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
//    When the price cell is selected, we need it to ask the viewer for a price
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_PRICE {
            let alert = UIAlertController(title: "Price", message: "Enter a price", preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                
                // If the user presses okay, check if the price is valid, if not, display an error
                guard let priceString = alert.textFields?.first?.text, priceString != "", let price = Int(priceString), price > 0, price < 10000 else {
                    self.displayMessage(title: "Error", message: "Enter a valid price. Price must be greater than $0 and less than $10000")
                    return
                }
                
                // This must mean price is valid, set it as a property
                self.photocardPrice = price

                tableView.reloadData()
            })
            
            alert.addAction(cancelAction)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_CONDITION {
            return "ⓘ Tap to change the details of the sale listing"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "ⓘ Tap 'Save' to save/create listing"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_PRICE {
            return indexPath
        } else if indexPath.section == SECTION_LOCATION {
            return indexPath
        }
        
        return nil
    }
    
    // MARK: View Controller Methods
    
    // When the user wants to select the location, we need delegation so that once a location has been selected on the map, it will tell this class the selected location
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMapView" {
            let destination = segue.destination as! MapViewController
            destination.hidesBottomBarWhenPushed = true
            destination.delegate = self
        }
    }
    
// MARK: Delegation Methods
    
    // This method will inform this class the location the user selected as well as its name
    func locationChanged(_ location: CLLocationCoordinate2D, _ title: String) {
        self.photocardLocation = LocationAnnotation(title: title, coordinate: location)
        tableView.reloadData()
    }
    
//    Whenever the condition has been changed on the segmented control of the condition cell, this method will inform the current class the changed condition
    func changedCondition(_ condition: Int) {
        self.photocardCondition = condition
        tableView.reloadData()
    }

}
