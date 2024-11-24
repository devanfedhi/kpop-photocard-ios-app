//
//  ConditionFilterTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 28/5/2024.
//

import UIKit

// This cell contains two segmented controls that denote the worst and best condition to be filtered on the buy market
class ConditionFilterTableViewCell: UITableViewCell {

    //    Whenever either of the segment controls has changed, we need to tell the filter view controller the updated conditions based on the sliders.
        
    //    Also change the label to be the condition of the segmented control
        
        // Input checking will be done in the filter screen
    
    @IBAction func conditionHiSegmentChanged(_ sender: Any) {
        delegate?.conditionHiChanged(condition: conditionHiSegment.selectedSegmentIndex)
        conditionHiLabel.text = self.intToCondition(conditionHiSegment.selectedSegmentIndex)
    }

    @IBAction func conditionLoSegmentChanged(_ sender: Any) {
        delegate?.conditionLoChanged(condition: conditionLoSegment.selectedSegmentIndex)
        conditionLoLabel.text = self.intToCondition(conditionLoSegment.selectedSegmentIndex)
    }
    @IBOutlet weak var conditionHiSegment: UISegmentedControl!

    @IBOutlet weak var conditionLoSegment: UISegmentedControl!
    
    @IBOutlet weak var conditionHiLabel: UILabel!

    @IBOutlet weak var conditionLoLabel: UILabel!
    
    weak var delegate: FilterConditionChangedDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
//    Converts an integer to the appropriate condition string
    func intToCondition(_ conditionInt: Int) -> String {
        switch conditionInt {
        case 0:
            return "Poor"
        case 1:
            return "Fair"
        case 2:
            return "Excellent"
        case 3:
            return "Brand New"
        default:
            return "Poor"
        }
    }

}

