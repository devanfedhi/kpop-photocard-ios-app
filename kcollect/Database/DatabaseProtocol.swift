//
//  DatabaseProtocol.swift
//  LAB03
//
//  Created by Devan Fedhi on 24/3/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case userPhotocard
    case userFavouritePhotocard
    case userSales
    case all
    case album
    case profile
    case buyMarket
    case externalProfile
    case home
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    func onAlbumChange(change: DatabaseChange, allAlbums: [String])
    
    func onUserPhotocardChange(change: DatabaseChange, allPhotocards: [Photocard])
    
    func onFavGroupChange(change: DatabaseChange, group: GroupSingle?)
    
    func onFavIdolChange(change: DatabaseChange, idol: IdolSingleGroup?)
    
    func onUserSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing])
    
    func onBuyMarketChange(change: DatabaseChange, allSaleListings: [SaleListing])
    
    func onUserFavouritePhotocardChange(change: DatabaseChange, allPhotocards: [Photocard])
    
    func onBiasIdolSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing])
    
    func onBiasGroupSaleListingChange(change: DatabaseChange, allSaleListings: [SaleListing])
    
}

protocol DatabaseProtocol: AnyObject {
    
//    User/Login related methods/attributes
    var currentUser: FirebaseAuth.User? {get set}
    var userLoggedIn: Bool {get set}
    func setupUser(name: String)
    func authLogout()
    func cleanup()
    
//    Methods to add and remove a database listeners
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)

//    Methods to fetch specific data from Firebase
    func setupAlbumListener(_ group: Group, _ idol: Idol)
    func setupUserPhotocardListener()
    func setupProfileSettingsListener()
    func setupUserSaleListingListener()
    func setupBuyMarketListener(priceLo: Float, priceHi: Float, conditionLo: Int, conditionHi: Int, dateLo: Date, dateHi: Date)
    func setupFavouritePhotocardsListener()
    func setupExternalProfileListener(_ userUID: String)
    func setupHomeBiasListener()
    
//    Stores a list of all groups (and since each group consists of all of its idols) and all idols, fetched from the API call
    var allGroups: [String: Group] {get set}
//    Method to make an API call and parse the data
    func startSearch()
    
//    Adding and deleting a photocard
    func addPhotocard(_ group: Group, _ idol: Idol, _ album: String, _ image: UIImage)
    func deletePhotocard(_ photocard: Photocard)
    
    //    Method called to changed the favourite status or image of a photocard
    func changeFavourite(_ photocard: Photocard, _ bool: Bool)
    func changePhotocardImage(_ photocard: Photocard, _ image: UIImage)
    
//    Creating a sale listing, deleting and purchasing a sale listing
    func addSaleListing(_ photocard: Photocard, _ price: Int, _ location: LocationAnnotation, _ condition: Int)
    func deleteSaleListing(_ saleListing: SaleListing)
    func purchasePhotocard(_ saleListing: SaleListing)
    
//    Array of all the bias idol/group sale listings presented on the home screen
    var allBiasIdolSaleListing: [SaleListing] {get set}
    var allBiasGroupSaleListing: [SaleListing] {get set}
    
    //    Stores the users favourite Group/Idol as required in the profiel view controller
    var favGroup: GroupSingle? {get set}
    var favIdol: IdolSingleGroup? {get set}
    
//    Sets the favourite group and idol for the current user
    func addFavGroup(_ group: Group)
    func addFavIdol(_ idol: Idol)
    
    //    Functions to reset the bias idol/group for a user
    func clearBiasIdol()
    func clearBiasGroup()
}
