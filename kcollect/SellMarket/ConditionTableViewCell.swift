//
//  ConditionTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 9/5/2024.
//



import UIKit

// This cell simply stores the segmented control for the conditions of the photocard
class ConditionTableViewCell: UITableViewCell {

    weak var delegate: ConditionChangeDelegate?

//    Whenever the condition value of the segmented control has been changed, obtained the selected segment index and inform the create sale listing view controller of the change in condition
    @IBAction func conditionValueChanged(_ sender: Any) {
        delegate?.changedCondition(conditionSegmentedControl.selectedSegmentIndex)
    }
    
    @IBOutlet weak var conditionSegmentedControl: UISegmentedControl!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()


    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
