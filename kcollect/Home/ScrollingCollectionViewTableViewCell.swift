//
//  ScrollingCollectionViewTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 31/5/2024.
//

import UIKit

// This class is the table view cell that contains the scrolling collection view
class ScrollingCollectionViewTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    /*
    Reference: https://www.youtube.com/watch?v=oX7PVj-wiGI&ab_channel=SwiftCourse
    
    To implement the scrolling feature, I followed this tutorial from Youtube. However, I had to make some changes such that it can suit my app, for example, modifying the photocard cell size, having it be on a table view controller rather than a view controller, as well implementing manual scrolling that auto adjusts to the page.
    */
    
    weak var delegate: SaleListingSelectedDelegate?
    @IBOutlet weak var pages: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var saleListings = [SaleListing]()
    
    var index = 0
    var increasing = true
    var timer: Timer?
    
    // MARK: Table View Cell Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.dataSource = self
        collectionView.delegate = self

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    // MARK: Miscellaneous Methods
    
    // This method is called whenever the table view is updated (fetched new data from Firebase). This method will essentially just reload the collection view as well as invalidate the existing timer
    func reloadData() {
        collectionView.reloadData()
        
        if saleListings.count > 0 {
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 6.0, target: self, selector: #selector(pageSetup), userInfo: nil, repeats: true)
        }
    
    }
    
    // This method is essentially the method called during the timer, which scrolls the collection view up, then down, then up, then down, etc
    @objc func pageSetup(){
        if increasing {
            if index < saleListings.count - 1 {
                index = index + 1
            } else {
                increasing = false
                index = index - 1
            }
        } else {
            if index > 0 {
                index = index - 1
            } else {
                increasing = true
                index = index + 1
            }
        }
        
        pages.numberOfPages = saleListings.count
        pages.currentPage = index
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: true)
        
    }
    
    // Invalidates the timer for the collection view, if it exists.
    func invalidateTimer() {
        timer?.invalidate()
    }
    
    // MARK: Collection View Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        saleListings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "saleListingCell", for: indexPath) as! SaleListingCollectionViewCell
        
        cell.photocardImage.image = self.saleListings[indexPath.row].photocard.image
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    // Whenever a sale listing is selected, we need to tell the main view controller "Home" the sale listing selected. This view controller will then segue to the buy photocard page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let saleListing = self.saleListings[indexPath.row]
        
        delegate?.saleListingSelected(saleListing)
    }
    
    // MARK: Scroll View Methods

    // Called when the user ends dragging the scroll view. If it is not currently decelerating, that is, it isn't moving, we need to re-adjust the collection view to "centre" on a cell
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let pageWidth = scrollView.frame.width
            let page = floor(scrollView.contentOffset.x / pageWidth)
            pages.numberOfPages = saleListings.count
            pages.currentPage = Int(page)
            index = Int(page)
            
            
            collectionView.scrollToItem(at: IndexPath(item: Int(page), section: 0), at: .right, animated: true)
        }
    }

    
    // Called when the scroll view stops decelerating. There is a scenario when a user does end draging, but it is still decelerating. So we need to wait until it has indeed decelerated, and once it does re-adjust to "centre" on a cell
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let pageWidth = scrollView.frame.width
        let page = floor(scrollView.contentOffset.x / pageWidth)
        pages.numberOfPages = saleListings.count
        pages.currentPage = Int(page)
        index = Int(page)
    
        
        collectionView.scrollToItem(at: IndexPath(item: Int(page), section: 0), at: .right, animated: true)
  
    }

}
