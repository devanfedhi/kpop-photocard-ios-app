//
//  PhotocardDetailsTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This class is similar to the AddPhotocardTableViewController, but for an already existing photocard
class PhotocardDetailsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, FavouriteSwitchDelegate, TakePhotoDelegate {

    var photocard: Photocard?
    
    var favourite: Bool?
    
    var image: UIImage?
    
    let SECTION_IMAGE = 0
    let SECTION_IDOL = 1
    let SECTION_GROUP = 2
    let SECTION_ALBUM = 3
    let SECTION_FAVOURITE = 4
    
    let CELL_IMAGE = "imageCell"
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"
    let CELL_FAVOURITE = "favouriteCell"

    weak var databaseController: DatabaseProtocol?
    
    // Whenever the user attempts to delete a photocard, give them a warning message in case it was a mis click.
    @IBAction func deletePhotocard(_ sender: Any) {
        
        let alert = UIAlertController(title: "Are you sure you want to delete this photocard?", message: "This will delete any associated data with this photocard, such as any sale listings on the market. If this photocard is favourited, it will be removed from the display on your profile.", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // If the user confirms that they want to delete the photocard, tell our database controller to handle the deletion
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            
            guard let photocard = self.photocard else {
                return
            }
            self.databaseController?.deletePhotocard(photocard)
            self.navigationController?.popViewController(animated: true)

            self.tableView.reloadData()
        })
        
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)

    }
    
    // Whenever the user attempts to save changes to a photocard, we need to make sure everything is valid
    @IBAction func saveChanges(_ sender: Any) {
        guard let userID = self.databaseController?.currentUser?.uid else {
            displayMessage(title: "Error", message: "No user logged in!")
        return
        }
        
        guard let image = image else {
            displayMessage(title: "Error", message: "Cannot add photocard until an image has been selected!")
            return
        }
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            displayMessage(title: "Error", message: "Image data could not be compressed")
            return
        }
        
        guard let photocard = photocard, let favourite = favourite else {
            return
        }
        
        // If it has, then we can begin to change the image of the photocard as well as change its favourite status
        databaseController?.changePhotocardImage(photocard, image)
        databaseController?.changeFavourite(photocard, favourite)
        
        
        
        navigationController?.popViewController(animated: true)
        
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

    }
    
    // MARK: Table View Methods
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    

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
        case SECTION_FAVOURITE:
            return 1
        default:
            return 0
        }
    }
    
    // Create the contents of each of our cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // This cell just displays an image of the photocard
        if indexPath.section == SECTION_IMAGE {
            
            let imageCell = tableView.dequeueReusableCell(withIdentifier: CELL_IMAGE, for: indexPath) as! AddPhotocardImageTableViewCell
            
            if let image = image {
                imageCell.photocardImage.image = image
            }
            
            // Delegation is required since whenever the photo is changed (button selected at table view cell), we need to tell this controller that is has
            imageCell.delegate = self
            return imageCell
            
            // This cell just displays the idol
        } else if indexPath.section == SECTION_IDOL {
            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
            
            
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = photocard?.idolName
            
            return idolCell
            
            // This cell just displays the group
        } else if indexPath.section == SECTION_GROUP {
            
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
    
            
            groupCell.textLabel?.text = "Group:"
            
            groupCell.detailTextLabel?.text = photocard?.groupName
            
            return groupCell
            
            // This cell just displays the album
        } else if indexPath.section == SECTION_ALBUM {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            
            albumCell.detailTextLabel?.text = photocard?.albumName
             
            return albumCell
            
            // This cell just displays the favourite switch cell
        } else {
            let favouriteCell = tableView.dequeueReusableCell(withIdentifier: CELL_FAVOURITE, for: indexPath) as! FavouriteTableViewCell
            
            // Delegation is required since whenever the favourite switch is changed, to true or fakse, we need to tell this controller that is has
            favouriteCell.delegate = self
            
            if let initial = self.photocard?.favourite {
                favouriteCell.favouriteSwitch.setOn(initial, animated: false)
            }
            
            return favouriteCell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "Save changes or delete photocard here"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "ⓘ Tap 'Change Photo' to change photo"
        } else if section == SECTION_FAVOURITE {
            return "ⓘ Favourite photocard to display on profile"
        }
        
        return nil
    }
    
    // MARK: Delegation methods
    
    // This method tells the current view controller the current (most updated) state of the switch
    func switchChanged(_ bool: Bool) {
        self.favourite = bool
        
    }

    // MARK: Camera Controller Methods
    
    // This method is called wheneber the change photo button is called in the image cell. Users can be able to choose between taking a picture or choosing a picture from their camera roll
    func takePhoto() {
        let controller = UIImagePickerController()
        controller.allowsEditing = false
        controller.delegate = self
        let actionSheet = UIAlertController(title: nil, message: "Select Option:", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
            controller.sourceType = .camera
            self.present(controller, animated: true, completion: nil)
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { action in
            controller.sourceType = .photoLibrary
            self.present(controller, animated: true, completion: nil)
        }
        
        let albumAction = UIAlertAction(title: "Photo Album", style: .default) { action in
            controller.sourceType = .savedPhotosAlbum
            self.present(controller, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(cameraAction)
        }
        
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverPresentationController.permittedArrowDirections = []
        }
        
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(albumAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // Once an image is picked, we need to tell the view controller which image has been picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            image = pickedImage
            tableView.reloadData()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}
