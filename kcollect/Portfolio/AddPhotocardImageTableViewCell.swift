//
//  AddPhotocardImageTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 30/5/2024.
//

import UIKit

// Cell for the image of a photocard along with the change photo button
class AddPhotocardImageTableViewCell: UITableViewCell {
    
    weak var delegate: TakePhotoDelegate?

    // If the take photo button has been pressed, we need to tell the main view controller that it has been pressed
    @IBAction func takePhoto(_ sender: Any) {
        delegate?.takePhoto()
        
    }
    @IBOutlet weak var photocardImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
