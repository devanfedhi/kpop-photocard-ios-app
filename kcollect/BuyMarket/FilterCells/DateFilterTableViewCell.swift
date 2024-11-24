//
//  DateTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 28/5/2024.
//

import UIKit

// This cell contains two date pickers that denote the oldest and most recent date to be filtered on the buy market
class DateFilterTableViewCell: UITableViewCell {

    //    Whenever either of the date pickers has changed, we need to tell the filter view controller the updated dates based on the date pickers.
        
    //    Also change the label to be the date of the date picker in an appropriate format
        
        // Input checking will be done in the filter screen
    @IBAction func dateHiDatePickerChanged(_ sender: Any) {
        delegate?.dateHiChanged(date: dateHiDatePicker.date)
        dateHiLabel.text = self.getDateAsString(date: dateHiDatePicker.date)
    }

    @IBAction func dateLoDatePickerChanged(_ sender: Any) {
        delegate?.dateLoChanged(date: dateLoDatePicker.date)
        dateLoLabel.text = self.getDateAsString(date: dateLoDatePicker.date)
    }
    @IBOutlet weak var dateHiDatePicker: UIDatePicker!
    @IBOutlet weak var dateLoDatePicker: UIDatePicker!
    @IBOutlet weak var dateHiLabel: UILabel!
    @IBOutlet weak var dateLoLabel: UILabel!
    
    weak var delegate: FilterDateChangedDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

//    This method will just convert the date to a more readable string
    func getDateAsString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
}
