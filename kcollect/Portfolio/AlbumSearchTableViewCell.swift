//
//  AlbumSearchTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 27/5/2024.
//

import UIKit


// The cell that contains text field and a button for adding a new album
class AlbumSearchTableViewCell: UITableViewCell {
    
    // Whenever the album button is clicked, we need to tell the add photocard page the name of the album that was in the text field
    @IBAction func addAlbumButton(_ sender: Any) {
        guard let album = albumTextField.text, album.isEmpty == false else {
            return
        }
        self.delegate?.addAlbumButtonClicked(album)
        
    }
    @IBOutlet weak var albumTextField: UITextField!
    weak var delegate: SearchAlbumTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
