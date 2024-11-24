//
//  AddPhotocardTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// This class is for adding a new photocard to a user's portfolio
class AddPhotocardTableViewController: UITableViewController, GroupChangeDelegate, IdolChangeDelegate, AlbumChangeDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TakePhotoDelegate {
    
    var image: UIImage?
    
    var selectedGroup: Group?
    var selectedIdol: Idol?
    var selectedAlbum: String?
    
    let SECTION_IMAGE = 0
    let SECTION_GROUP = 1
    let SECTION_IDOL = 2
    let SECTION_ALBUM = 3
    
    let CELL_IMAGE = "imageCell"
    let CELL_IDOL = "idolCell"
    let CELL_GROUP = "groupCell"
    let CELL_ALBUM = "albumCell"

    weak var databaseController: DatabaseProtocol?
    
    // Whenever a user wants to add a photocard, we need to ensure that everything has been appropriately selected/defined.
    @IBAction func addPhotocard(_ sender: Any) {
        guard let userID = self.databaseController?.currentUser?.uid else {
            displayMessage(title: "Error", message: "No user logged in!")
        return
        }
        
        guard let selectedGroup = selectedGroup, let selectedIdol = selectedIdol, let selectedAlbum = selectedAlbum else {
            displayMessage(title: "Error", message: "Cannot add photocard until a group, idol and album have been selected!")
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
        
        // If so, then we need to tell Firebase to add the photocard
        databaseController?.addPhotocard(selectedGroup, selectedIdol, selectedAlbum, image)
        
        navigationController?.popViewController(animated: true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // This basically begins the API search of the K-POP data we need
        databaseController?.startSearch()
        
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
            
        // This cell just displays the group
        } else if indexPath.section == SECTION_GROUP {
            let groupCell = tableView.dequeueReusableCell(withIdentifier: CELL_GROUP, for: indexPath)
            
            groupCell.textLabel?.text = "Group:"
            groupCell.detailTextLabel?.text = selectedGroup?.name ?? "N/A"
            
            return groupCell
            
            // This cell just displays the idol
        } else if indexPath.section == SECTION_IDOL {
            
            let idolCell = tableView.dequeueReusableCell(withIdentifier: CELL_IDOL, for: indexPath)
    
            idolCell.textLabel?.text = "Idol:"
            
            idolCell.detailTextLabel?.text = selectedIdol?.name ?? "N/A"
            
            return idolCell
            
//            This cell just displays the album
        } else {
            let albumCell = tableView.dequeueReusableCell(withIdentifier: CELL_ALBUM, for: indexPath)
    
            albumCell.textLabel?.text = "Album:"
            albumCell.detailTextLabel?.text = selectedAlbum ?? "N/A"
            
            return albumCell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "ⓘ Tap 'Save' to save changes"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_IMAGE {
            return "ⓘ Tap 'Change Photo' to change photo"
        } else if section == SECTION_ALBUM {
            return "ⓘ Tap to classify your photocard"
        }
        
        return nil
    }
    
    // Users should not be able to interact with the image cell.
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == SECTION_IMAGE {
            return nil
        }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: View Controller Methods
    
    // Only perform the segue to Idol if a group has been selected. Only perform the segue to Album if a group and idol has been selected.
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showIdolSelect" && selectedGroup == nil {
            displayMessage(title: "Error", message: "Select a K-POP group before you select an idol")
            return false

        } else if identifier == "showAlbumSelect" && ( selectedGroup == nil || selectedIdol == nil ) {
            displayMessage(title: "Error", message: "Select a K-POP group & idol before you select an album")
            return false

        }
        
        return true
    }
    
    // Delegation is required when segueing to the respective table view controllers since we need to know the selected album/idol/group
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showGroupSelect" {
            let destination = segue.destination as! GroupTableViewController
                        
            destination.delegate = self

        } else if segue.identifier == "showIdolSelect" {
            let destination = segue.destination as! IdolTableViewController
                        
            destination.delegate = self
            
            destination.selectedGroup = self.selectedGroup
            
            destination.showAllIdols = false

        } else if segue.identifier == "showAlbumSelect" {
            let destination = segue.destination as! AlbumTableViewController
            
            destination.delegate = self
            
            destination.selectedGroup = self.selectedGroup
            destination.selectedIdol = self.selectedIdol
            
            // Force unwrap is okay since we have already checked this in the shouldPerformSegue() method
            databaseController?.setupAlbumListener(self.selectedGroup!, self.selectedIdol!)
        }
    }
    
    // MARK: Delegation Methods
    
    // These methods essentially tell this view controller, from the Idol/Group/Album table view controller which Idol/Group/Album has been selected by the user
    
    func changedToAlbum(_ album: String) {
        selectedAlbum = album
        tableView.reloadData()
    }
    
    func changedToGroup(_ group: Group) {
        
        selectedGroup = group
        selectedIdol = nil
        selectedAlbum = nil
        
        tableView.reloadData()
        
    }
    
    func changedToIdol(_ idol: Idol) {
 
        selectedIdol = idol
        
        selectedAlbum = nil
        tableView.reloadData()
    }

    // MARK: Camera Controller Methods
    
    // This method is called wheneber the change photo button is called in the image cell. Users can be able to choose between taking a picture or choosing a picture from their camera roll
    func takePhoto(){
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
