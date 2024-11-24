//
//  FavouritePhotocardsTableViewCell.swift
//  kcollect
//
//  Created by Devan Fedhi on 21/5/2024.
//

import UIKit

// This class is the table view cell that holds the collection view displaying a user's favourite photocards on their profile
class FavouritePhotocardsTableViewCell: UITableViewCell {

    var allFavouritePhotocard = [Photocard]()
    weak var databaseController: DatabaseProtocol?
    
    weak var delegate: PhotocardSelectedDelegate?

    @IBOutlet weak var collectionView: UICollectionView!
    
    let CELL_PHOTOCARD = "photocardCell"
    
    // MARK: Table View Cell Methods
    
    override func prepareForReuse() {
        collectionView.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.reloadData()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        collectionView.delegate = self
        collectionView.dataSource = self
    
        
    }
    


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }
    


}

// MARK: Collection View Methods

extension FavouritePhotocardsTableViewCell: UICollectionViewDelegate {

}

extension FavouritePhotocardsTableViewCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allFavouritePhotocard.count
    }

    // Create the content of the photocard cell. This is simply just just image of the photocard and the name of the idol of the photocard
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_PHOTOCARD, for: indexPath) as! FavouritePhotocardsCollectionViewCell
        cell.backgroundColor = .secondarySystemFill
    
        cell.imageView.image = allFavouritePhotocard[indexPath.row].image
        cell.photocardLabel.text = allFavouritePhotocard[indexPath.row].idolName
        return cell
    }
    
    // Whenever a photocard is selected, we need to tell the profile view controller which photocard has been selected so that it can segue to the photocard details page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.photocardSelected(allFavouritePhotocard[indexPath.row])
    }
    
    
    
    

}
