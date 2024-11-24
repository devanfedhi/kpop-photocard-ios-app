import MapKit

// This file lists out all of the protocols used throughout the application

// All of these protocols are used to communicate between view controllers, table/collection view cells, etc.

protocol GroupChangeDelegate: AnyObject {
    func changedToGroup(_ group: Group)
}

protocol IdolChangeDelegate: AnyObject {
    func changedToIdol(_ idol: Idol)
}

protocol AlbumChangeDelegate: AnyObject {
    func changedToAlbum(_ album: String)
}

protocol SearchAlbumTableViewCellDelegate: AnyObject {
    func addAlbumButtonClicked(_ album: String)
}

protocol FavouriteSwitchDelegate: AnyObject {
    func switchChanged(_ bool: Bool)
}

protocol LocationChangedDelegate: AnyObject {
    func locationChanged(_ location: CLLocationCoordinate2D, _ title: String)
}


protocol ConditionChangeDelegate: AnyObject {
    func changedCondition(_ condition: Int)
}

protocol LocationUserSelectedDelegate: AnyObject {
    func locationSelected(_ location: LocationAnnotation)
    
    func userSelected(_ user: User)
}

protocol SortOrderSelected: AnyObject {
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing])
}

protocol FilterPriceChangedDelegate: AnyObject {
    func priceLoChanged(price: Float)
    
    func priceHiChanged(price: Float)
}

protocol FilterConditionChangedDelegate: AnyObject {
    func conditionLoChanged(condition: Int)
    
    func conditionHiChanged(condition: Int)
}

protocol FilterDateChangedDelegate: AnyObject {
    func dateLoChanged(date: Date)
    
    func dateHiChanged(date: Date)
}


protocol FilterChangedDelegate: AnyObject {
    func filterChanged(priceLo: Float, priceHi: Float, conditionLo: Int, conditionHi: Int, dateLo: Date, dateHi: Date)
}

protocol UserSelectedDelegate: AnyObject {
    func userSelected(_ userString: String, _ useruID: String)
}

protocol PhotocardSelectedDelegate: AnyObject {
    func photocardSelected(_ photocard: Photocard)
}

protocol TakePhotoDelegate: AnyObject {
    func takePhoto()
}

protocol SaleListingSelectedDelegate: AnyObject {
    func saleListingSelected(_ saleListing: SaleListing)
}

protocol SettingsDelegate: AnyObject {
    func deleteBiasIdol()
    
    func deleteBiasGroup()
}
