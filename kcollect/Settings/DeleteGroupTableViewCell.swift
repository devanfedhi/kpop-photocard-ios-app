//
//  DeleteGroupTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 1/6/2024.
//

import UIKit

class DeleteGroupTableViewCell: UITableViewCell {
    
    @IBAction func deleteButtonGroup(_ sender: Any) {
        delegate?.deleteBiasGroup()
    }
    weak var delegate: SettingsDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }

}
