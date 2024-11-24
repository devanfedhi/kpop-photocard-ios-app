//
//  ExternalPhotocardDetailsTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This view controller shows the detials of a specific photocard. Only shows the image, group and album. Only supposed to be used for external users (users not of the current user)
class ExternalPhotocardDetailsTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    var photocard: Photocard?
    
    let SECTION_IMAGE = 0
    let SECTION_IDOL = 1
    let SECTION_GROUP = 2
    let SECTION_ALBUM = 3
    
    let CELL_IMAGE = "imageCell"
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"

    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        guard let photocard = photocard else {
            return
        }
        
        
        print(photocard)
        
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
        default:
            return 0
        }
    }
    
    // Create the content for the table view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // This cell just displays an image of the photocard
        if indexPath.section == SECTION_IMAGE {
            let imageCell = tableView.dequeueReusableCell(withIdentifier: CELL_IMAGE, for: indexPath) as! PhotocardImageTableViewCell
            
            guard let photocard = photocard else {
                return imageCell
            }
            
            
            imageCell.photocardImage.image = photocard.image
            
            return imageCell
            
            // This cell just displays the idol of the photocard
        } else if indexPath.section == SECTION_IDOL {
            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = photocard?.idolName
            
            return idolCell
            
            // This cell just displays the group of the photocard
        } else if indexPath.section == SECTION_GROUP {
            
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = photocard?.groupName
            
            return groupCell
            
            // This cell just displays the album of the photocard
        } else {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = photocard?.albumName
             
            return albumCell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }



}
