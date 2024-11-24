//
//  PriceTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 28/5/2024.
//

import UIKit

// This cell contains two sliders that denote the minimum and maximum price filters on the buy market
class PriceFilterTableViewCell: UITableViewCell {

//    Whenever either of the sliders has changed, we need to tell the filter view controller the updated prices based on the sliders.
    
//    Also change the label to be the price of the slider
    
    // Input checking will be done in the filter screen
    @IBAction func priceHiSliderChanged(_ sender: Any) {
        delegate?.priceHiChanged(price: priceHiSlider.value)
        priceHiLabel.text = "$\(Int(round(priceHiSlider.value)))"
    }
    @IBAction func priceLoSliderChanged(_ sender: Any) {
        delegate?.priceLoChanged(price: priceLoSlider.value)
        priceLoLabel.text = "$\(Int(round(priceLoSlider.value)))"
    }
    
    @IBOutlet weak var priceLoLabel: UILabel!
    @IBOutlet weak var priceHiSlider: UISlider!
    @IBOutlet weak var priceLoSlider: UISlider!
    @IBOutlet weak var priceHiLabel: UILabel!
    
    weak var delegate: FilterPriceChangedDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
