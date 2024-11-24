//
//  BuyFilterTableViewController.swift
//  kcollect
//
//  Created by Devan Fedhi on 22/5/2024.
//

import UIKit
import CoreLocation

// This class displays all of the filters that can be applied when searching on the buy market
class BuyFilterTableViewController: UITableViewController, FilterPriceChangedDelegate, FilterDateChangedDelegate, FilterConditionChangedDelegate {
    
    /*
    Reference: https://www.youtube.com/watch?v=ETS4jI0EaY4&ab_channel=SwiftfulThinking
    
    To implement the filter feature, I used this video tutorial to help me learn how to filter snapshot data from Firebase, including how to set-up a component key to handle filters with multiple conditions
    */
    
    weak var delegate: FilterChangedDelegate?
    
    let SECTION_PRICE = 0
    let SECTION_CONDITION = 1
    let SECTION_DATE = 2
    
    let CELL_PRICE = "priceCell"
    let CELL_CONDITION = "conditionCell"
    let CELL_DATE = "dateCell"
    
//    These are the current setting of the filter. This may change if the user decides to change them,
    var priceLower = Float(0)
    var priceUpper = Float(10000)
    var conditionLower = 0
    var conditionUpper = 3
    var dateLower = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!
    var dateUpper = Calendar.current.date(from: DateComponents(year: 2070, month: 1, day: 1))!
    
//    These are the bounds of each of the filters. The filters cannot go beyond these bounds
    var priceLowerBound = Float(0)
    var priceUpperBound = Float(10000)
    var conditionLowerBound = 0
    var conditionUpperBound = 3
    var dateLowerBound = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1))!
    var dateUpperBound = Calendar.current.date(from: DateComponents(year: 2070, month: 1, day: 1))!

    let PRICE = "Price"
    let CONDITION = "Condition"
    let LOCATION = "Location"
    let DATE = "Date"
    
    weak var databaseController: DatabaseProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(named: "Background")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
//  When this button is selected, apply the filters to the buy market, if they are appropriate filters
    @IBAction func saveButton(_ sender: Any) {
        
//        First, check if the filters are valid.
        var errorMessage = ""
        if priceLower > priceUpper {
            errorMessage += "Price lower bound must be less than price upper bound. "
        }
        
        if conditionLower > conditionUpper {
            errorMessage += "Worst condition needs to be a condition equal to best condition, or worse than best condition. "

        }
        
        if dateLower > dateUpper {
            errorMessage += "Date lower bound must be earlier than date upper bound. "

        }
        
//        If it is not valid, show an error message
        if !errorMessage.isEmpty {
            displayMessage(title: "Error", message: errorMessage)
            return
        }
        
//        At this point, the filter is valid. So update the current filters that are being used, that is, send them to the buy photocard view controller
        delegate?.filterChanged(priceLo: priceLower, priceHi: priceUpper, conditionLo: conditionLower, conditionHi: conditionUpper, dateLo: dateLower, dateHi: dateUpper)
        
//        Fetch the buy market listings from firebase again using the appropriate filters
//        databaseController?.setupBuyMarketListener(priceLo: priceLower, priceHi: priceUpper, conditionLo: conditionLower, conditionHi: conditionUpper, dateLo: dateLower, dateHi: dateUpper)
        
        navigationController?.popViewController(animated: true)
        
        
    }
    
//    MARK: Table Views Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }

//    Creates the content for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        The price cell will contain two sliders that the user can use to modify the price filter
        if indexPath.section == SECTION_PRICE {

            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_PRICE, for: indexPath) as! PriceFilterTableViewCell
            
            cell.delegate = self
            
//            Define the bounds of the sliders
            cell.priceLoSlider.minimumValue = priceLowerBound
            cell.priceLoSlider.maximumValue = priceUpperBound
            cell.priceHiSlider.minimumValue = priceLowerBound
            cell.priceHiSlider.maximumValue = priceUpperBound
            
//            Set the value of the slider as the current price filter and display it on the label
            cell.priceLoSlider.value = priceLower
            cell.priceHiSlider.value = priceUpper
            
            cell.priceLoLabel.text = "$\(Int(round(cell.priceLoSlider.value)))"
            cell.priceHiLabel.text = "$\(Int(round(cell.priceHiSlider.value)))"
            
            
            
            return cell
            
//            The condition cell will contain two segmented controls that the user can use to modify the condition filter
        }  else if indexPath.section == SECTION_CONDITION {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CONDITION, for: indexPath) as! ConditionFilterTableViewCell
            
            cell.delegate = self
            
            //            Set the value of the segmented control as the current condition filter and display it on the label
            cell.conditionLoSegment.selectedSegmentIndex = conditionLower
            cell.conditionHiSegment.selectedSegmentIndex = conditionUpper
            
            cell.conditionHiLabel.text = cell.intToCondition(cell.conditionHiSegment.selectedSegmentIndex)
            cell.conditionLoLabel.text = cell.intToCondition(cell.conditionLoSegment.selectedSegmentIndex)
        
            
            return cell
            
//            The date cell will contain two date pickers that the user can use to mdoify the date filter
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: CELL_DATE, for: indexPath) as! DateFilterTableViewCell
            
            cell.delegate = self
            
            //            Define the bounds of the date pickers
            cell.dateLoDatePicker.minimumDate = dateLowerBound
            cell.dateLoDatePicker.maximumDate = dateUpperBound
            cell.dateHiDatePicker.minimumDate = dateLowerBound
            cell.dateHiDatePicker.maximumDate = dateUpperBound
            
            //            Set the value of the date pickers as the current date filter and display it on the label
            cell.dateLoDatePicker.date = dateLower
            cell.dateHiDatePicker.date = dateUpper
            
            cell.dateLoLabel.text = cell.getDateAsString(date: cell.dateLoDatePicker.date)
            cell.dateHiLabel.text = cell.getDateAsString(date: cell.dateHiDatePicker.date)
            
            
            return cell
            
        }
 
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == SECTION_PRICE {
            return "Price Filter"
        } else if section == SECTION_DATE {
            return "Date Filter"
        } else {
            return "Condition Filter"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == SECTION_PRICE {
            return "ⓘ Move the slider to change the range of prices to search from"
        } else if section == SECTION_DATE {
            return "ⓘ Select range of dates to search from"
        } else {
            return "ⓘ Select the range of conditions to search from"
        }
    }
    
//    MARK: Delegation Methods
    
//    These methods when any of the filters has been changed on any of the cells. The cells will call on one of these methods which informs the current view controller of what filter has been changed
    
    func priceLoChanged(price: Float) {
        self.priceLower = price
    }
    
    func priceHiChanged(price: Float) {
        self.priceUpper = price
    }
    
    func dateLoChanged(date: Date) {
        self.dateLower = date
    }
    
    func dateHiChanged(date: Date) {
        self.dateUpper = date
    }
    
    func conditionLoChanged(condition: Int) {
        self.conditionLower = condition
    }
    
    func conditionHiChanged(condition: Int) {
        self.conditionUpper = condition
    }

}
