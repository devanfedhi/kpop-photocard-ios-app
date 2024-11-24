//
//  DeleteTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 1/6/2024.
//

import UIKit

class DeleteIdolTableViewCell: UITableViewCell {

    @IBAction func deleteButtonIdol(_ sender: Any) {
        delegate?.deleteBiasIdol()
    }
    
    weak var delegate: SettingsDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
