//
//  FavouriteTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 20/5/2024.
//

import UIKit

// The cell that containts a switch (to decide if a photocard is favourited or not)
class FavouriteTableViewCell: UITableViewCell {
    
    // Whenever the switch has been activated true or false, we need to tell the photocard details page the new state of the switch
    @IBAction func favouriteSwitchAction(_ sender: Any) {
        self.delegate?.switchChanged(favouriteSwitch.isOn)
    }
    
    weak var delegate: FavouriteSwitchDelegate?
    
    @IBOutlet weak var favouriteLabel: UILabel!
    @IBOutlet weak var favouriteSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        favouriteLabel.text = "Favourite:"
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}


