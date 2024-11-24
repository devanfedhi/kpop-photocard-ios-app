//
//  FirebaseController.swift
//  LAB03
//
//  Created by Devan Fedhi on 6/4/2024.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseStorage
import MapKit


class FirebaseController: NSObject, DatabaseProtocol {
    
    override init() {
        
    //        Configure and initialise each of the Firebase frameworks
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        storage = Storage.storage()
        storageRef = storage
        imageRef = storage.reference().child("images")
        
    //        Initally no user will be logged in
        userLoggedIn = false
        
        super.init()
        
    }

// MARK: User Related Attributes
    var currentUser: FirebaseAuth.User?
    var userLoggedIn: Bool
    var authController: Auth
    
// MARK: Stores All App Listeners
    var listeners = MulticastDelegate<DatabaseListener>()
    
// MARK: Reference to Firebase Firestore Database/Collection References
    var database: Firestore
    var albumRef: CollectionReference?
    var userPhotocardRef: CollectionReference?

//    MARK: Reference to Firebase storage
    var storage: Storage
    var storageRef: Storage?
    var imageRef: StorageReference?
    
//    MARK: Store Groups, Idols, Albums from API call/Firestore
    var allGroups: [String: Group] = [:]
    var allAlbums: [String] = []
       
// MARK: Array For Photocards/Sale Listings
    var allPhotocardsForCurrentUser = [Photocard]()
    var allSaleListingsForCurrentUser = [SaleListing]()
    var allBuyMarketSaleListings = [SaleListing]()
    var allFavouritePhotocardsForCurrentUser = [Photocard]()
    var allFavouritePhotocardsForCertainUser = [Photocard]()
    var allBiasIdolSaleListing = [SaleListing]()
    var allBiasGroupSaleListing =  [SaleListing]()
    
// MARK: Stores Favourite Group/Idol for Current User
    var favGroup: GroupSingle?
    var favIdol: IdolSingleGroup?
    
// MARK: User/Login related methods
    
    // Whenever a user is registered into the system, add a users document in the users collection with their email, uid and name
    func setupUser(name: String) {
        Task {
            guard let user = currentUser else {
                return
            }
            
            
            
            let userRef = database.collection("users")
            
            try await userRef.document(user.uid).setData([
                "email": user.email,
                "uid": user.uid,
                "name": name
            ])
        }
    }
    
//    Signs a user out of the system and Firebase
    func authLogout() {
        do {
            try authController.signOut()
            currentUser = nil
            userLoggedIn = false
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }

    }
    
    func cleanup() {
        
    }
    
// MARK: Listener Related Methods
    
//    Adds database listener to the list of listeners
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
    //    Provide listener with initial immediate results depending on what type of listener it is
        
    //    We need to check the listener type of the listener to find out what information to provide.
        if listener.listenerType == ListenerType.userPhotocard || listener.listenerType == ListenerType.all {
            listener.onUserPhotocardChange(change: .update, allPhotocards: self.allPhotocardsForCurrentUser)
        }
        
        if listener.listenerType == ListenerType.userSales || listener.listenerType == ListenerType.all {
            listener.onUserSaleListingChange(change: .update, allSaleListings: self.allSaleListingsForCurrentUser)
        }
        
        if listener.listenerType == ListenerType.home || listener.listenerType == ListenerType.all {
            listener.onBiasIdolSaleListingChange(change: .update, allSaleListings: self.allBiasIdolSaleListing)
            listener.onFavIdolChange(change: .update, idol: self.favIdol)
        }
    

    }
    
    //    Removes database listener from the list of listeners
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
// MARK: Setup Profile Settings For Current User
    
//    This fetches the favourite idol and group for the current user from Firestore
    func setupProfileSettingsListener() {
        
//        Reset the favourite idol and group to nil since we will be fetching this
        favIdol = nil
        favGroup = nil
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Obtain a reference to the users document in the users collection
        let userRef = database.collection("users").document(currentUserUID)
        
//        Obtain the document from firestore
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching document: \(error)")
            } else {
                
                
                if let document = document, document.exists {
                    // Document exists, so you can access its data
                    guard let data = document.data() else {
                        return
                    }
                    
                    // Find the idol document reference
                    if let favIdolRef = data["fav_idol_ref"] as? DocumentReference {
                        favIdolRef.getDocument { (document, error) in
                            
//                            Error handling
                            if let error = error {
                                print("Error getting favIdol document: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let document = document, document.exists else {
                                print("Fav idol ref does not exist")
                                return
                            }
                            
                            // Extract data from the idol document
                            guard let favIdolData = document.data() else {
                                return
                            }
                            
                            // Extract the current path
                            let currentPath = document.reference.path
                            
                            // Split the path into components
                            let pathComponents = currentPath.split(separator: "/")
                            
                            // Check if there are enough components to go one directory up
                            guard pathComponents.count >= 4 else {
                                print("Path does not have enough components to navigate one directory up")
                                return
                            }
                            
                            // Construct the path one directory up to find the group document
                            let newPath = pathComponents.prefix(pathComponents.count - 2).joined(separator: "/")
                            
                            // Get the reference to the group document one directory up
                            let favIdolGroupRef = Firestore.firestore().document(newPath)
                            
                            // Fetch the group document at the new path
                            favIdolGroupRef.getDocument { (newDocument, newError) in
                                
                                if let newError = newError {
                                    print("Error getting document: \(newError.localizedDescription)")
                                } else if let newDocument = newDocument, newDocument.exists, let favIdolGroupData = newDocument.data() {
                                    
                                    // Create the IdolSingleGroup instance using the new document data
                                    guard let idolName = favIdolData["name"] as? String, let idolGroupName = favIdolGroupData["name"] as? String else {
                                        return
                                    }
                                    
                                    let idol = IdolSingleGroup(name: idolName, group: idolGroupName)
                                    
//                                    Set the favourite idol as this new idol
                                    self.favIdol = idol
                                    
//                                    Update the profile to let them know of the favourite idol change
                                    self.listeners.invoke { (listener) in
                                        if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                                            listener.onFavIdolChange(change: .update, idol: idol)
                                        }
                                        
                                    }
                                    

                                } else {
                                    print("New document does not exist or there was an error")
                                }
                            }
                        }
                    }
                    
                    // Find the group document reference
                    if let favGroupRef = data["fav_group_ref"] as? DocumentReference {
                        favGroupRef.getDocument { (document, error) in
                            
                            //                            Error handling
                            if let error = error {
                                print("Error getting favGroup document: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let document = document, document.exists else {
                                print("Fav group ref does not exist")
                                return
                            }
                            
                            // Extract data from the group document
                            guard let favGroupData = document.data() else {
                                return
                            }
                            
                            // Obtain the group name
                            guard let favGroupName = favGroupData["name"] as? String else {
                                return
                            }
                            
                            // Create the GroupSingle instance using the new document data, and set the favourite group for the current user
                            let favGroup = GroupSingle(name: favGroupName)
                            self.favGroup = favGroup
                            
                            //                                    Update the profile to let them know of the favourite group change
                            self.listeners.invoke { (listener) in
                                if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                                    listener.onFavGroupChange(change: .update, group: favGroup)
                                }
                            
                            }
                        }
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
    }
     
// MARK: Setup Favourite Photocards Listener For Current User
     
//    This fetches all of the favourite photocards for the current user
    func setupFavouritePhotocardsListener() {
        
//        Remove everything since some photocards may have been changed
        allFavouritePhotocardsForCurrentUser.removeAll()
        
//        Refresh the profile page to reset everything
        self.listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                listener.onUserFavouritePhotocardChange(change: .update, allPhotocards: self.allFavouritePhotocardsForCurrentUser)
            }
        }
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Obtain a reference to the user-photocards collection which will list all of the photocards for the current user
        userPhotocardRef = database.collection("users").document(currentUserUID).collection("photocards")
        
        // Loop through every photocard in the user-photocard collection
        userPhotocardRef?.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user photocards: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            for document in documents {
                self.parseUserFavouritePhotocardsSnapshot(snapshot: document)
            }
        }
 
    }
    
//    This method will parse the document snapshot of the user's photocard collection
    func parseUserFavouritePhotocardsSnapshot(snapshot: QueryDocumentSnapshot) {
        
        let documentData = snapshot.data()
        
//        The field in this document is a document reference, so we need to get the document from this document reference
        if let photocardRef = documentData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
                // Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
//                Obtains the image name (which is the photocardUID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))
                
//                Parse everyrhing into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
                // If the photocard is not a favourited photocard, terminate early.
                if photocard.favourite == false {
                    return
                }
                
//                Add the favourite photocard to the allFavouritePhotocardsForCurrentUser array
                self.allFavouritePhotocardsForCurrentUser.append(photocard)
                
//                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else {
                    return
                }
                
//                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
//                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    
//                    Set the image of the photocard
                    photocard.image = image
                    
//                    Update the profile page with the new added photocard
                    self.listeners.invoke { (listener) in
                        if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                            listener.onUserFavouritePhotocardChange(change: .update, allPhotocards: self.allFavouritePhotocardsForCurrentUser)
                        }
                    }
                    
//                    This must mean we need to download the image from Firebase Storage
                } else {
                    
                    if let imageFilePath = photocard.imageFilePath {
                        
//                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
//                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
//                                Sert the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
//                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                                
                                //                    Update the profile page with the new added photocard
                                self.listeners.invoke { (listener) in
                                    if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                                        listener.onUserFavouritePhotocardChange(change: .update, allPhotocards: self.allFavouritePhotocardsForCurrentUser)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
// MARK: Setup Favourite Photocards Listener & Profile Settings For External User
    
    func setupExternalProfileListener(_ userUID: String) {

        //        Obtain a reference to the users document in the users collection
        let userRef = database.collection("users").document(userUID)
        
        //        Obtain the document from firestore
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching document: \(error)")
            } else {
                
                if let document = document, document.exists {
                    // Document exists, so you can access its data
                    guard let data = document.data() else {
                        return
                    }
                    
                    // Find the idol document reference
                    if let favIdolRef = data["fav_idol_ref"] as? DocumentReference {
                        favIdolRef.getDocument { (document, error) in
                            
                            //                            Error handling
                            if let error = error {
                                print("Error getting favIdol document: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let document = document, document.exists else {
                                print("Fav idol ref does not exist")
                                return
                            }
                            
                            // Extract data from the idol document
                            guard let favIdolData = document.data() else {
                                return
                            }
                            
                            // Extract the current path
                            let currentPath = document.reference.path
                            
                            // Split the path into components
                            let pathComponents = currentPath.split(separator: "/")
                            
                            // Check if there are enough components to go one directory up
                            guard pathComponents.count >= 4 else {
                                print("Path does not have enough components to navigate one directory up")
                                return
                            }
                            
                            // Construct the path one directory up to find the group document
                            let newPath = pathComponents.prefix(pathComponents.count - 2).joined(separator: "/")
                            
                            // Get the reference to the document one directory up
                            let favIdolGroupRef = Firestore.firestore().document(newPath)
                            
                            // Fetch the group document at the new path
                            favIdolGroupRef.getDocument { (newDocument, newError) in
                                if let newError = newError {
                                    print("Error getting document: \(newError.localizedDescription)")
                                } else if let newDocument = newDocument, newDocument.exists, let favIdolGroupData = newDocument.data() {
                                    
                                    // Create the IdolSingleGroup instance using the new document data
                                    guard let idolName = favIdolData["name"] as? String, let idolGroupName = favIdolGroupData["name"] as? String else {
                                        return
                                    }
                                    
                                    //                                    Set the favourite idol as this new idol
                                    let idol = IdolSingleGroup(name: idolName, group: idolGroupName)
                                    
                                    //                                    Update the external profile to let them know of the favourite idol change
                                    self.listeners.invoke { (listener) in
                                        if listener.listenerType == ListenerType.externalProfile || listener.listenerType == ListenerType.all {
                                            listener.onFavIdolChange(change: .update, idol: idol)
                                        }
                                    }
                                } else {
                                    print("New document does not exist or there was an error")
                                }
                            }
                        }
                    }
                    
                    // Find the group document reference
                    if let favGroupRef = data["fav_group_ref"] as? DocumentReference {
                        favGroupRef.getDocument { (document, error) in
                            
                            //                            Error handling
                            if let error = error {
                                print("Error getting favGroup document: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let document = document, document.exists else {
                                print("Fav group ref does not exist")
                                return
                            }
                            
                            // Extract data from the group document
                            guard let favGroupData = document.data() else {
                                return
                            }
                            
                            // Obtain the group name
                            guard let favGroup = favGroupData["name"] as? String else {
                                return
                            }
                            
                            //                                    Update the external profile to let them know of the favourite group change
                            self.listeners.invoke { (listener) in
                                if listener.listenerType == ListenerType.externalProfile || listener.listenerType == ListenerType.all {
                                    listener.onFavGroupChange(change: .update, group: GroupSingle(name: favGroup))
                                }
                            }
                        }
                    }
                } else {
                    print("Document does not exist")
                }
            }

        }
        
        //        Remove everything since some photocards may have been changed
        allFavouritePhotocardsForCertainUser.removeAll()
        
        //        Obtain a reference to the user-photocards collection which will list all of the photocards for the external user
        userPhotocardRef = database.collection("users").document(userUID).collection("photocards")
        
        // Loop through every photocard in the user-photocard collection
        userPhotocardRef?.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user photocards: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            for document in documents {
                self.parseExternalUserFavouritePhotocardsSnapshot(snapshot: document)
            }
            
            
            
        }
    }
    
    //    This method will parse the document snapshot of the user's photocard collection
    func parseExternalUserFavouritePhotocardsSnapshot(snapshot: QueryDocumentSnapshot) {
        
        let documentData = snapshot.data()
        
        //        The field in this document is a document reference, so we need to get the document from this document reference
        if let photocardRef = documentData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
                // Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
                //                Obtains the image name (which is the photocardUID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))
                
                //                Parse everyrhing into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
                // If the photocard is not a favourited photocard, terminate early.
                if photocard.favourite == false {
                    return
                }
                
                //                Add the favourite photocard to the allFavouritePhotocardsForCertainUser array
                self.allFavouritePhotocardsForCertainUser.append(photocard)
  
                //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else {
                    return
                }
                
                
                //                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
                //                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    //                    Set the image of the photocard
                    photocard.image = image
                    
                    //                    Update the external profile page with the new added photocard
                    self.listeners.invoke { (listener) in
                        if listener.listenerType == ListenerType.externalProfile || listener.listenerType == ListenerType.all {
                            listener.onUserFavouritePhotocardChange(change: .update, allPhotocards: self.allFavouritePhotocardsForCertainUser)
                        }
                    }
                    
                    
//                    This must mean we need to download the image from Firebase Storage
                } else {

                    if let imageFilePath = photocard.imageFilePath {
                        
                        //                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
                        //                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
                                //                                Set the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
                                //                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                                
                                //                    Update the profile page with the new added photocard
                                self.listeners.invoke { (listener) in
                                    if listener.listenerType == ListenerType.externalProfile || listener.listenerType == ListenerType.all {
                                        listener.onUserFavouritePhotocardChange(change: .update, allPhotocards: self.allFavouritePhotocardsForCertainUser)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
// MARK: Setup Home Bias Idol/Group Sale Listing Listener
    
    func setupHomeBiasListener() {
        // Reset the favourite idol and group of the current user since we will be fetching this
        favIdol = nil
        favGroup = nil
        
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Obtain a reference to the current users document in the users collection
        let userRef = database.collection("users").document(currentUserUID)
        
//        Obtain the user document
        userRef.getDocument { (document, error) in
            
//            If at any point this errors, just begin the bias idol/group setup without the current users biases
            if let error = error {
                self.setupBiasIdol()
                self.setupBiasGroup()
            } else if let document = document, document.exists, let data = document.data() {
                
//                Obtain the favourite idol references
                if let favIdolRef = data["fav_idol_ref"] as? DocumentReference {
                    favIdolRef.getDocument { (document, error) in
                        
                        if let error = error {
                            self.setupBiasIdol()
                            
//                            Obtain the idol bias and the group that they are in
                        } else if let document = document, document.exists, let favIdolData = document.data() {
                            // Extract the current path
                            let currentPath = document.reference.path
                            
                            // Split the path into components
                            let pathComponents = currentPath.split(separator: "/")
                            
                            // Check if there are enough components to go one directory up to get to the group document
                            guard pathComponents.count >= 4 else {
                                print("Path does not have enough components to navigate one directory up")
                                self.setupBiasIdol()
                                return
                            }
                            
                            // Construct the path one directory up to get to the grouup document
                            let newPath = pathComponents.prefix(pathComponents.count - 2).joined(separator: "/")
                            
                            // Get the reference to the document one directory up to the group document
                            let favIdolGroupRef = Firestore.firestore().document(newPath)
                            
                            // Fetch the group document at the new path
                            favIdolGroupRef.getDocument { (newDocument, newError) in
                                if let newError = newError {
                                    print("Error getting document: \(newError.localizedDescription)")
                                    self.setupBiasIdol()
                                    
//                                    Group document has been founded, so set the favourite idol
                                } else if let newDocument = newDocument, newDocument.exists, let favIdolGroupData = newDocument.data() {
                                    
                                    // Create the IdolSingleGroup instance using the new document data
                                    if let idolName = favIdolData["name"] as? String, let idolGroupName = favIdolGroupData["name"] as? String {
                                        self.favIdol = IdolSingleGroup(name: idolName, group: idolGroupName)
                                        self.setupBiasIdol()
                                    } else {
                                        self.setupBiasIdol()
                                    }
                                    
                                } else {
                                    print("New document does not exist or there was an error")
                                    self.setupBiasIdol()
                                }
                            }
                            //            If at any point this errors, just begin the bias idol/group setup without the current users biases
                        } else {
                            self.setupBiasIdol()
                        }
                    }
                    //            If at any point this errors, just begin the bias idol/group setup without the current users biases
                } else {
                    self.setupBiasIdol()
                }
                    
                
                //                Obtain the favourite group references
                if let favGroupRef = data["fav_group_ref"] as? DocumentReference {
                    favGroupRef.getDocument { (document, error) in
                        
                        if let error = error {
                            self.setupBiasGroup()
                            
//                            Get the group name and as it as the favourite group
                        } else if let document = document, document.exists, let favGroupData = document.data() {
                            
                            if let groupName = favGroupData["name"] as? String {
                                self.favGroup = GroupSingle(name: groupName)
                                self.setupBiasGroup()
                            } else {
                                self.setupBiasGroup()
                            }
                            
        
                            
                            //            If at any point this errors, just begin the bias idol/group setup without the current users biases
                        } else {
                            self.setupBiasGroup()
                        }
                    }
                    
                    //            If at any point this errors, just begin the bias idol/group setup without the current users biases
                } else {
                    self.setupBiasGroup()
                }
            } else {
                self.setupBiasIdol()
                self.setupBiasGroup()
            }

        }
    }
    
//    At this point, the current user may or may not have a favourite group. They may not if they have not set one or if the fetch failed
    func setupBiasGroup() {
        
//        Update the profile to let them know of the new favourite group
        self.listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.home || listener.listenerType == ListenerType.all {
                listener.onFavGroupChange(change: .update, group: self.favGroup)
            }
        }

        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Obtain a reference to the market collection
        let buySaleListingRef = database.collection("market")
//
        
//        Get every document in the market collection
        buySaleListingRef.getDocuments { (querySnapshot, error) in
            
//            Error handling
            if let error = error {
                print("Error fetching sale listings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }

            for document in documents {
                self.parseBiasGroupSaleListingSnapshot(snapshot: document)
            }
            
        }
    }
        
    //    At this point, the current user may or may not have a favourite idol. They may not if they have not set one or if the fetch failed
    func setupBiasIdol() {
        
        //        Update the profile to let them know of the new favourite idol
        self.listeners.invoke { (listener) in
    
            if listener.listenerType == ListenerType.home || listener.listenerType == ListenerType.all {
                listener.onFavIdolChange(change: .update, idol: self.favIdol)
            }
        }
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
        //        Obtain a reference to the market collection
        let buySaleListingRef = database.collection("market")
        
        //        Get every document in the market collection
        buySaleListingRef.getDocuments { (querySnapshot, error) in
            
            //            Error handling
            if let error = error {
                print("Error fetching sale listings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            for document in documents {
                self.parseBiasIdolSaleListingSnapshot(snapshot: document)
            }
            
        }
    }
    
//    Parse through every document in the market collection and only obtain ones that have a matching favourite group
    func parseBiasGroupSaleListingSnapshot(snapshot: QueryDocumentSnapshot) {

//        Obtain all the sale listing data, in preparation for parsing
        let saleListingData = snapshot.data()
        
        guard let salePrice = saleListingData["price"] as? Int else {
            return
        }
        
        guard let saleDateString = saleListingData["date"] as? String, let saleDate = self.getDateFromString(dateString: saleDateString) else {
            return
        }
        
        guard let saleConditionInt = saleListingData["condition"] as? Int else {
            return
        }
        
        guard let saleLocationTitle = saleListingData["location"] as? String, let saleLocationLat = saleListingData["location_lat"] as? Double, let saleLocationLong = saleListingData["location_long"] as? Double else {
            return
        }
        
//        Parse the location of the sale listing
        let saleLocation = LocationAnnotation(title: saleLocationTitle, coordinate: CLLocationCoordinate2D(latitude: saleLocationLat, longitude: saleLocationLong))
            
//        Obtain the photocard from the photocard document reference of the market sale listing document
        if let photocardRef = saleListingData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
//                Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
//                Obtain the imaage name (which is the photocard UID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))

//                Prase the photocard data into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
//                Create the sale listing
                let saleListing = SaleListing(photocard,salePrice,saleLocation,saleConditionInt, saleDate)
                
//                 Add a maximum of 5 sale listings on the featured market listings on the home page.
                

                if self.allBiasGroupSaleListing.count < 5 {
                    
                    //                If the user has a group bias set, check if the current sale listing matches with their group bias, and if so add it.
                                    
                    //                If the user does not have a group bias set, add random sale listings
                    
//                    Make sure not to add sale listings of the current user
                    if let groupName = photocard.groupName?.lowercased(), let favGroup = self.favGroup?.name.lowercased() {
                        if groupName == favGroup {
                            if photocard.userUID != self.currentUser?.uid {
                                self.allBiasGroupSaleListing.append(saleListing)
                            } else {
                                return
                            }
                        } else {
                            return
                        }
                    } else {
                        if photocard.userUID != self.currentUser?.uid {
                            self.allBiasGroupSaleListing.append(saleListing)
                        } else {
                            return
                        }
                    }
                } else {
                    
//                    If more than 5 market listings already exist, randomly swap some out
                    if Bool.random()  {
                        self.allBiasGroupSaleListing.append(saleListing)
                        
                        // Ensure there is at least one element to remove
                        if self.allBiasGroupSaleListing.count > 1 {
                            self.allBiasGroupSaleListing.remove(at: Int.random(in: 0..<self.allBiasGroupSaleListing.count))
                        }
                    } else {
                        return
                    }
                    
                }
                
                //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else { // change
                    return
                }
                
                //                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
                //                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    //                    Set the image of the photocard
                    photocard.image = image
                    
                    //                    This must mean we need to download the image from Firebase Storage
                } else {
                    if let imageFilePath = photocard.imageFilePath {
                        
                        //                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
                        //                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
                                //                                Set the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
                                //                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                                
                            }
                        }
                    }
                }
                //                    Update the home page with the new added photocard sale listing
                self.listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.home || listener.listenerType == ListenerType.all {
                        listener.onBiasGroupSaleListingChange(change: .update, allSaleListings: self.allBiasGroupSaleListing)
                    }
                }
            }
        }
    }
    
    //    Parse through every document in the market collection and only obtain ones that have a matching favourite idol
    func parseBiasIdolSaleListingSnapshot(snapshot: QueryDocumentSnapshot) {

        //        Obtain all the sale listing data, in preparation for parsing
        let saleListingData = snapshot.data()
    
        
        guard let salePrice = saleListingData["price"] as? Int else {
            return
        }
        
        guard let saleDateString = saleListingData["date"] as? String, let saleDate = self.getDateFromString(dateString: saleDateString) else {
            return
        }
        guard let saleConditionInt = saleListingData["condition"] as? Int else {
            return
        }
        guard let saleLocationTitle = saleListingData["location"] as? String, let saleLocationLat = saleListingData["location_lat"] as? Double, let saleLocationLong = saleListingData["location_long"] as? Double else {
            return
        }
        
        //        Parse the location of the sale listing
        let saleLocation = LocationAnnotation(title: saleLocationTitle, coordinate: CLLocationCoordinate2D(latitude: saleLocationLat, longitude: saleLocationLong))
            
        //        Obtain the photocard from the photocard document reference of the market sale listing document
        if let photocardRef = saleListingData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
                //                Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
                //                Obtain the imaage name (which is the photocard UID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))

                
                //                Prase the photocard data into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
                //                Create the sale listing
                let saleListing = SaleListing(photocard,salePrice,saleLocation,saleConditionInt, saleDate)
                
                //                 Add a maximum of 5 sale listings on the featured market listings on the home page.
                if self.allBiasIdolSaleListing.count < 5 {
                    
                    //                If the user has a group idol set, check if the current sale listing matches with their idol bias, and if so add it.
                                    
                    //                If the user does not have a idol bias set, add random sale listings
                    
//                    Make sure not to add sale listings of the current user
                    if let idolName = photocard.idolName?.lowercased(), let idolGroupName = photocard.groupName?.lowercased(), let favIdol = self.favIdol?.name.lowercased(), let favIdolsGroup = self.favIdol?.group.lowercased() {
                        if (idolName == favIdol) && (idolGroupName == favIdolsGroup) {
                            if photocard.userUID != self.currentUser?.uid {
                                self.allBiasIdolSaleListing.append(saleListing)

                            } else {
                                return
                            }
                        } else {
                            return
                        }
                    } else {
                        
                        if photocard.userUID != self.currentUser?.uid {
                            self.allBiasIdolSaleListing.append(saleListing)
                        } else {
                            return
                        }
                    }
                } else {
                    //                    If more than 5 market listings already exist, randomly swap some out
                    if Bool.random()  {
                        self.allBiasIdolSaleListing.append(saleListing)
                        
                        // Ensure there is at least one element to remove
                        if self.allBiasIdolSaleListing.count > 1 {
                            self.allBiasIdolSaleListing.remove(at: Int.random(in: 0..<self.allBiasIdolSaleListing.count))
                        }
                    } else {
                        return
                    }
                    
                }
                
                //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else { // change
                    return
                }
                
                //                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
                //                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    //                    Set the image of the photocard
                    photocard.image = image
                    
                    //                    This must mean we need to download the image from Firebase Storage
                    
                } else {
                    if let imageFilePath = photocard.imageFilePath {
                        
                        //                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
                        //                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
                                //                                Set the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
                                //                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                            
                            }
                        }
                    }
                }
                
                //                    Update the home page with the new added photocard sale listing
                self.listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.home || listener.listenerType == ListenerType.all {
                        listener.onBiasIdolSaleListingChange(change: .update, allSaleListings: self.allBiasIdolSaleListing)
                    }
                }
            }
        }
    }
    
    // MARK: Setup Buy Market Data From Firestore
    
//    Obtains all of the buy market listings from firestore that much a set of filtets
    func setupBuyMarketListener(priceLo: Float, priceHi: Float, conditionLo: Int, conditionHi: Int, dateLo: Date, dateHi: Date) {
        
//        Reset all of the current buy market listings
        allBuyMarketSaleListings.removeAll()
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Obtain a reference to the market collection, applying the appropriate filters. This involves the creation of a composite key on Firebase
        let buySaleListingRef = database.collection("market").whereField("price", isGreaterThanOrEqualTo: Int(round(priceLo))).whereField("price", isLessThanOrEqualTo: Int(round(priceHi))).whereField("condition", isGreaterThanOrEqualTo: conditionLo).whereField("condition", isLessThanOrEqualTo: conditionHi).whereField("date", isGreaterThanOrEqualTo: getDateAsString(date: dateLo)).whereField("date", isLessThanOrEqualTo: getDateAsString(date: dateHi))

        
        // Fetch all of the buy market documents that match the filter
        buySaleListingRef.getDocuments { (querySnapshot, error) in
            
//            Error handling
            if let error = error {
                print("Error fetching sale listings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            for document in documents {
                self.parseBuyMarketSnapshot(snapshot: document)
            }
            
        }
    }
    
//    Parse through each buy market document, create it as a sale listing and add it to the buy market sale listing list
    func parseBuyMarketSnapshot(snapshot: QueryDocumentSnapshot) {

        //        Obtain all the sale listing data, in preparation for parsing
        let saleListingData = snapshot.data()
    
        guard let salePrice = saleListingData["price"] as? Int else {
            return
        }
        
        guard let saleDateString = saleListingData["date"] as? String, let saleDate = self.getDateFromString(dateString: saleDateString) else {
            return
        }
        guard let saleConditionInt = saleListingData["condition"] as? Int else {
            return
        }
        guard let saleLocationTitle = saleListingData["location"] as? String, let saleLocationLat = saleListingData["location_lat"] as? Double, let saleLocationLong = saleListingData["location_long"] as? Double else {
            return
        }
        
        //        Parse the location of the sale listing
        let saleLocation = LocationAnnotation(title: saleLocationTitle, coordinate: CLLocationCoordinate2D(latitude: saleLocationLat, longitude: saleLocationLong))
            
        //        Obtain the photocard from the photocard document reference of the market sale listing document
        if let photocardRef = saleListingData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
                //                Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
                //                Obtain the imaage name (which is the photocard UID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))

                //                Prase the photocard data into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
                //                Create the sale listing
                let saleListing = SaleListing(photocard,salePrice,saleLocation,saleConditionInt, saleDate)
                
                // Add the photocard to the array, only if it not the current user's sale listing
                
                if photocard.userUID != self.currentUser?.uid {
                    self.allBuyMarketSaleListings.append(saleListing)
                } else {
                    return
                }

                //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else {
                    return
                }
                
                //                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
                //                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    //                    Set the image of the photocard
                    photocard.image = image
                    
                    //                    This must mean we need to download the image from Firebase Storage
                } else {

                    if let imageFilePath = photocard.imageFilePath {
                        
                        //                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
                        //                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
                                //                                Set the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
                                //                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                                
                            }
                        }
                    }
                }
                
                //                    Update the home page with the new added photocard sale listing
                self.listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.buyMarket || listener.listenerType == ListenerType.all {
                        listener.onBuyMarketChange(change: .update, allSaleListings: self.allBuyMarketSaleListings)
                    }
                }
            }
        }
    }
    
// MARK: Setup Current User's Sale Listings
    
    //    Obtains all of the sell market listings for a current user from firestore
    func setupUserSaleListingListener() {
        
        //        Reset all of the current sell market listings
        allSaleListingsForCurrentUser.removeAll()
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
        //        Obtain a reference to the users photocards on sale collection reference
        let userSaleListingRef = database.collection("users").document(currentUserUID).collection("photocards_on_sale")
        
        // Fetch all of the sell market documents for the current user
        userSaleListingRef.getDocuments { (querySnapshot, error) in
            
            //            Error handling
            if let error = error {
                print("Error fetching user sale listings: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            
            // Process the initial documents
            for document in documents {
                self.parseUserSaleListingsSnapshot(snapshot: document)
            }
            
        }
    }
    
    //    Parse through each sell market document, create it as a sale listing and add it to the current user's sell market sale listing list
    func parseUserSaleListingsSnapshot(snapshot: QueryDocumentSnapshot) {
        
        //        Obtain all the sale listing data, in preparation for parsing
        let documentData = snapshot.data()
        
        if let saleListingRef = documentData["sale_listing_ref"] as? DocumentReference {
            saleListingRef.getDocument { (document, error) in
                if let error = error {
                    print("Error getting sale listing document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let saleListingData = document.data() else {
                    return
                }
                
                guard let salePrice = saleListingData["price"] as? Int else {
                    return
                }
                
                guard let saleDateString = saleListingData["date"] as? String, let saleDate = self.getDateFromString(dateString: saleDateString) else {
                    return
                }
                guard let saleConditionInt = saleListingData["condition"] as? Int else {
                    return
                }
                guard let saleLocationTitle = saleListingData["location"] as? String, let saleLocationLat = saleListingData["location_lat"] as? Double, let saleLocationLong = saleListingData["location_long"] as? Double else {
                    return
                }
                
                //        Parse the location of the sale listing
                let saleLocation = LocationAnnotation(title: saleLocationTitle, coordinate: CLLocationCoordinate2D(latitude: saleLocationLat, longitude: saleLocationLong))
                
                //        Obtain the photocard from the photocard document reference of the market sale listing document
                if let photocardRef = saleListingData["photocard_ref"] as? DocumentReference {
                    photocardRef.getDocument { (document, error) in
                        //                Error handling
                        if let error = error {
                            print("Error getting photocard document: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let document = document, document.exists else {
                            print("Photocard document does not exist")
                            return
                        }
                        
                        // Extract data from the photocard document
                        guard let photocardData = document.data() else {
                            return
                        }
                        
                        //                Obtain the imaage name (which is the photocard UID)
                        guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                            return
                        }
                        let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))
                        
                        //                Prase the photocard data into the Photocard class
                        var photocard = Photocard()
                        photocard.albumName = photocardData["album"] as? String
                        photocard.albumUID = photocardData["album_uid"] as? String
                        photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                        photocard.groupName = photocardData["group"] as? String
                        photocard.groupUID = photocardData["group_uid"] as? String
                        photocard.idolName = photocardData["idol"] as? String
                        photocard.idolUID = photocardData["idol_uid"] as? String
                        photocard.imageFilePath = photocardData["image_file_path"] as? String
                        photocard.image = nil
                        photocard.photocardUID = photocardUIDClean
                        photocard.userEmail = photocardData["user"] as? String
                        photocard.userUID = photocardData["user_uid"] as? String
                        photocard.userName = photocardData["user_display_name"] as? String
                        photocard.favourite = photocardData["favourite"] as? Bool
                        
                        //                Create the sale listing
                        let saleListing = SaleListing(photocard,salePrice,saleLocation,saleConditionInt, saleDate)
                        
                        // Add the photocard to the array
                        self.allSaleListingsForCurrentUser.append(saleListing)
                        
                        //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                        let documentsDirectory = paths[0]
                        
                        guard let photocardUID = photocard.photocardUID else {
                            return
                        }
                        
                        //                File name of the image in local storage
                        let imageFileName = "/\(photocardUID).jpg"
                        
                        let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                        let image = UIImage(contentsOfFile: imageURL.path)
                        
                        //                This must mean we already have the image, so we can obtain the image directly from local storage
                        if let _ = image {
                            //                    Set the image of the photocard
                            photocard.image = image
                            
                            //                    Update the sell market page with the new added photocard sale listing
                            self.listeners.invoke { (listener) in
                                if listener.listenerType == ListenerType.userSales || listener.listenerType == ListenerType.all {
                                    listener.onUserSaleListingChange(change: .update, allSaleListings: self.allSaleListingsForCurrentUser)
                                }
                            }
                            
                            //                    This must mean we need to download the image from Firebase Storage
                        } else {

                            if let imageFilePath = photocard.imageFilePath {
                                
                                //                        Obtain a reference to Firebase Storage
                                let storageReference = Storage.storage().reference(withPath: imageFilePath)
                                
                                //                        Download image data
                                storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                                    if let error = error {
                                        print("Error downloading image from storage: \(error.localizedDescription)")
                                        
                                        //                                Set the image data to the photcard
                                    } else if let imageData = data {
                                        let image = UIImage(data: imageData)
                                        
                                        photocard.image = image
                                        
                                        //                                Save locally
                                        self.saveImageData(filename: imageFileName, imageData: imageData)
                                        
                                        //                    Update the sell market page with the new added photocard sale listing
                                        self.listeners.invoke { (listener) in
                                            if listener.listenerType == ListenerType.userSales || listener.listenerType == ListenerType.all {
                                                listener.onUserSaleListingChange(change: .update, allSaleListings: self.allSaleListingsForCurrentUser)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Setup Portfolio Page
    
//    Obtains all of the photocards for the current user from Firestore
    func setupUserPhotocardListener() {
        
//        Resets the photocards for current user list
        allPhotocardsForCurrentUser.removeAll()
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
//        Obtain a reference to the user photocards collection
        userPhotocardRef = database.collection("users").document(currentUserUID).collection("photocards")
        
        // Fetch all of the photocards for the user
        userPhotocardRef?.getDocuments { (querySnapshot, error) in
            
//            Error handling
            if let error = error {
                print("Error fetching user photocards: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }

            for document in documents {
                self.parseUserPhotocardsSnapshot(snapshot: document)
            }
            
        }
    }
    
//    For each photocard document in Firestore, parse it into the Photocard class and add to the users current photocard portfolio array
    func parseUserPhotocardsSnapshot(snapshot: QueryDocumentSnapshot) {
        
        let documentData = snapshot.data()
        
        //        Obtain the photocard from the photocard document reference of the market sale listing document
        if let photocardRef = documentData["photocard_ref"] as? DocumentReference {
            photocardRef.getDocument { (document, error) in
                
                //                Error handling
                if let error = error {
                    print("Error getting photocard document: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Photocard document does not exist")
                    return
                }
                
                // Extract data from the photocard document
                guard let photocardData = document.data() else {
                    return
                }
                
                //                Obtain the imaage name (which is the photocard UID)
                guard let photocardUIDWithJPG = photocardData["image_name"] as? String else {
                    return
                }
                let photocardUIDClean = String(photocardUIDWithJPG.prefix(photocardUIDWithJPG.count - 4))
                
                //                Prase the photocard data into the Photocard class
                var photocard = Photocard()
                photocard.albumName = photocardData["album"] as? String
                photocard.albumUID = photocardData["album_uid"] as? String
                photocard.date = self.getDateFromString(dateString: photocardData["date"] as! String)
                photocard.groupName = photocardData["group"] as? String
                photocard.groupUID = photocardData["group_uid"] as? String
                photocard.idolName = photocardData["idol"] as? String
                photocard.idolUID = photocardData["idol_uid"] as? String
                photocard.imageFilePath = photocardData["image_file_path"] as? String
                photocard.image = nil
                photocard.photocardUID = photocardUIDClean
                photocard.userEmail = photocardData["user"] as? String
                photocard.userUID = photocardData["user_uid"] as? String
                photocard.userName = photocardData["user_display_name"] as? String
                photocard.favourite = photocardData["favourite"] as? Bool
                
                // Add the photocard to the array
                self.allPhotocardsForCurrentUser.append(photocard)
                
                //                The code below will essentialy either download the photocard image from Firebase Storage, and then save locally, or obtain the photocard image directly from local storage if it already exists
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let documentsDirectory = paths[0]
                
                guard let photocardUID = photocard.photocardUID else { // change
                    return
                }
                
                //                File name of the image in local storage
                let imageFileName = "/\(photocardUID).jpg"
                
                let imageURL = documentsDirectory.appendingPathComponent(imageFileName)
                let image = UIImage(contentsOfFile: imageURL.path)
                
                //                This must mean we already have the image, so we can obtain the image directly from local storage
                if let _ = image {
                    
                    //                    Set the image of the photocard
                    photocard.image = image
                    
                    //                    Update the portfolio page with the new added photocard
                    self.listeners.invoke { (listener) in
                        if listener.listenerType == ListenerType.userPhotocard || listener.listenerType == ListenerType.all {
                            listener.onUserPhotocardChange(change: .update, allPhotocards: self.allPhotocardsForCurrentUser)
                        }
                    }
                    
                    //                    This must mean we need to download the image from Firebase Storage
                } else {
                    if let imageFilePath = photocard.imageFilePath {
                        
                        //                        Obtain a reference to Firebase Storage
                        let storageReference = Storage.storage().reference(withPath: imageFilePath)
                        
                        //                        Download image data
                        storageReference.getData(maxSize: 5 * 1024 * 1024) { data, error in
                            if let error = error {
                                print("Error downloading image from storage: \(error.localizedDescription)")
                                
                                //                                Set the image data to the photcard
                            } else if let imageData = data {
                                let image = UIImage(data: imageData)
                                
                                photocard.image = image
                                
                                //                                Save locally
                                self.saveImageData(filename: imageFileName, imageData: imageData)
                                
                                //                    Update the portfolio page with the new added photocard
                                self.listeners.invoke { (listener) in
                                    if listener.listenerType == ListenerType.userPhotocard || listener.listenerType == ListenerType.all {
                                        listener.onUserPhotocardChange(change: .update, allPhotocards: self.allPhotocardsForCurrentUser)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
// MARK: Seup album listener, obtian all albums for a particular group and album
    
    //    Get all the albums for a group and idol, if they exist.
        func setupAlbumListener(_ group: Group, _ idol: Idol) {
            
//            Obtain a reference to the albums collection
            albumRef = database.collection("groups").document(group.name.lowercased()).collection("idols").document(idol.name.lowercased()).collection("albums")
            
            // Fetch all of the couments in the albums collection
            albumRef?.getDocuments { (querySnapshot, error) in
                
                // Error handling
                if let error = error {
                    print("Error fetching albums: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                for document in documents {
                    self.parseAlbumsSnapshot(snapshot: document)
                }
            }
        }

        
    //   Parse each document snapshot, adding any new album into the all albums array
    func parseAlbumsSnapshot(snapshot: QueryDocumentSnapshot) {

        let documentData = snapshot.data()
        
//        Get the albums and add to list
        self.allAlbums.append(documentData["name"] as! String)

        // Inform the album table view controller once a new album has been added to the list
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.album || listener.listenerType == ListenerType.all {
                listener.onAlbumChange(change: .update, allAlbums: self.allAlbums)
            }
        }
    }
    
// MARK: Method to make an API call and parse the data
    //  Calls the K-POP api to get all the group and idol information
        func startSearch() {
            
//            The key for the API call required by RapidAPI
            let headers = [
                "X-RapidAPI-Key": "b766919d6fmsh8f66ce26709c7d6p1e987ajsn125a5d010277",
                "X-RapidAPI-Host": "k-pop.p.rapidapi.com"
            ]
            
            
//  Make the API search request
            let request = NSMutableURLRequest(url: NSURL(string: "https://k-pop.p.rapidapi.com/idols?q=F&by=Gender")! as URL,
                                                    cachePolicy: .useProtocolCachePolicy,
                                                timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers

            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    print(error as Any)
                } else if let data = data, let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        do {
//                            Decode the data from the API call
                            let decoder = JSONDecoder()
                            let volumeData = try decoder.decode(AllData.self, from: data)
                            if let cards = volumeData.idols {
                                
                                //  Parse all the data into their main Group and idol and add the allGroups dictionary
                                for idolData in cards {
                                    if let idolGroup = idolData.group, let idolName = idolData.name {
                                        if self.allGroups[idolGroup] == nil {
                                            self.allGroups[idolGroup] = Group(name: idolGroup)
                                        }
                                        
                                        self.allGroups[idolGroup]!.idols[idolName] = Idol(name: idolName, group: self.allGroups[idolGroup]!) // force unwrap okay, must exist
                                        
                                    }
                                    
                                    //    Parse all the data into their second Group and idol and add the allGroups dictionary
                                    if let secondIdolGroup = idolData.secondGroup, let idolName = idolData.name {
                                        if self.allGroups[secondIdolGroup] == nil {
                                            self.allGroups[secondIdolGroup] = Group(name: secondIdolGroup)
                                        }
                                        
                                        self.allGroups[secondIdolGroup]!.idols[idolName] = Idol(name: idolName, group: self.allGroups[secondIdolGroup]!) // force unwrap okay, must exist
                                        
                                    }
                                    
                                    //   Parse all the data into their  third Group and idol and add the allGroups dictionary
                                    if let thirdIdolGroup = idolData.thirdGroup, let idolName = idolData.name {
                                        if self.allGroups[thirdIdolGroup] == nil {
                                            self.allGroups[thirdIdolGroup] = Group(name: thirdIdolGroup)
                                        }
                                        
                                        self.allGroups[thirdIdolGroup]!.idols[idolName] = Idol(name: idolName, group: self.allGroups[thirdIdolGroup]!) // force unwrap okay, must exist
                                        
                                    }
                                    
                                }

                            }
                            
                         } catch let err {
                             print(err)
                         }

                    }
                }
            })

            dataTask.resume()
            
        }
    
// MARK: Adding and deleting a photocard
    
//    Add a photocard to the firestore database
    func addPhotocard(_ group: Group, _ idol: Idol, _ album: String, _ image: UIImage) {
        
//        Obtain the UID for the group, idol and album
        let groupUID = group.name.lowercased()
        let idolUID = idol.name.lowercased()
        let albumUID = album.lowercased()
        
//        This is the collection where we actually create the photocard
        let photocardRef = self.database.collection("photocards")
        
        let newPhotocardRef = photocardRef.document()
        
//        Define the filename for the photocard
        let filename = "/\(newPhotocardRef.documentID).jpg"
        
        // Create a reference to the file you want to upload
        let newImageRef = imageRef?.child(filename)
    
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        // Upload the image to Firebase storage
        let uploadTask = newImageRef?.putData(data, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata, error == nil else {
                return
            }
        }
        
//        Save image locally
        saveImageData(filename: filename, imageData: data)
        
//        Get the current date, which will represent the date and time the photocard was added
        let dateString = self.getCurrentDateAsString()
        
//        Obtain the users document reference, which will be used to store their photocards
        let userRef = self.database.collection("users").document(currentUser!.uid)

//        Obtain the users document collection
        userRef.getDocument{ (document, error) in
            
//            Error handling
            if let error = error {
                print("Error getting photocard document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("User document does not exist")
                return
            }
            
            // Extract data from the photocard document
            guard let userData = document.data() else {
                return
            }
            
//            Get the name of theuser
            let displayName = userData["name"] as! String
            
//            Add the photocard to the photocards collection
            newPhotocardRef.setData([
                "user": self.currentUser?.email,
                "user_uid": self.currentUser?.uid,
                "user_display_name": displayName,
                "group": group.name,
                "group_uid": groupUID,
                "idol": idol.name,
                "idol_uid": idolUID,
                "album": album,
                "album_uid": albumUID,
                "date": dateString,
                "image_name": newImageRef?.name,
                "image_file_path": newImageRef?.fullPath,
                "favourite": false
            ])
            
// Add the photocard to the user-photocard collection
            let userPhotocardsRef = userRef.collection("photocards")
            
            userPhotocardsRef.document(newPhotocardRef.documentID).setData([
                "photocard_ref": newPhotocardRef
                
            ])
            
//            Parse the photocard into the Photocard class
            var photocard = Photocard()
            photocard.albumName = album
            photocard.albumUID = albumUID
            photocard.date = self.getDateFromString(dateString: dateString)
            photocard.groupName = group.name
            photocard.groupUID = groupUID
            photocard.idolName = idol.name
            photocard.idolUID = idolUID
            photocard.imageFilePath = newImageRef?.fullPath
            photocard.image = image
            photocard.photocardUID = newPhotocardRef.documentID
            photocard.userEmail = self.currentUser?.email
            photocard.userUID = self.currentUser?.uid
            photocard.userName = displayName
            photocard.favourite = false
            
            // Add the photocard to the users portfolio array
            self.allPhotocardsForCurrentUser.append(photocard)
            
//            Update the portfolio page to inform them of the new photocard that was added to the current user's portfolio
            self.listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.userPhotocard || listener.listenerType == ListenerType.all {
                    listener.onUserPhotocardChange(change: .update, allPhotocards: self.allPhotocardsForCurrentUser)
                }
            }
            
//            Now we want to add the group, idol and album in an nested collection tree on Firestore. Add the group, idol and album collection/document if it does not already exist
            let groupRef = self.database.collection("groups")

            var documentGroupRef = groupRef.document(groupUID)
                
    //        This checks if the group already exists as a document or not. If it doesn't, create one
            documentGroupRef.getDocument{ (document, error) in
                if let document = document, document.exists {
                    print("document already exists")
                } else if let error = error {
                    print("error in getting document")
                } else {
                    groupRef.document(groupUID).setData([
                        "name": group.name
                    ])

                            
                }
            }
            
            //            Now we want to add the group, idol and album in an nested collection tree on Firestore. Add the group, idol and album collection/document if it does not already exist
            let idolRef = self.database.collection("groups").document(groupUID).collection("idols")
            
            var documentIdolRef = idolRef.document(idolUID)
            
            //        This checks if the idol already exists as a document or not. If it doesn't, create one
            documentIdolRef.getDocument{ (document, error) in
                if let document = document, document.exists {
                    print("document already exists")
                } else if let error = error {
                    print("error in getting document")
                } else {
                    idolRef.document(idolUID).setData([
                        "name": idol.name
                    ])
                            
                }
            }
            
            //            Now we want to add the group, idol and album in an nested collection tree on Firestore. Add the group, idol and album collection/document if it does not already exist
            let albumRef = self.database.collection("groups").document(groupUID).collection("idols").document(idolUID).collection("albums")
            
            var documentAlbumRef = albumRef.document(albumUID)
            
            //        This checks if the album already exists as a document or not. If it doesn't, create one
            documentAlbumRef.getDocument{ (document, error) in
                if let document = document, document.exists {
                    print("document already exists")
                } else if let error = error {
                    print("error in getting document")
                } else {
                    albumRef.document(albumUID).setData([
                        "name": album
                    ])
                            
                }
            }
            
//            Now add the photocard reference into the nested group, idol, album collection tree
            let photocardNestedRef = self.database.collection("groups").document(groupUID).collection("idols").document(idolUID).collection("albums").document(albumUID).collection("photocards")
            
            photocardNestedRef.document(newPhotocardRef.documentID).setData([
                "photocard_ref": newPhotocardRef
            ])
        }
        
    }
    
//    Deletes a photocard from the system, including the portfolio, sale listings, etc
    func deletePhotocard(_ photocard: Photocard) {
        
//        Delete the photocard from the sale listings
        self.setupUserSaleListingListener()
        
        for saleListing in self.allSaleListingsForCurrentUser {
            if saleListing.photocard == photocard {
                self.deleteSaleListing(saleListing)
                break
            }
            
            
        }
        
//        Get the uid for the photocard, user, group, idol and album
        guard var photocardUID = photocard.photocardUID, let userUID = photocard.userUID, let groupUID = photocard.groupUID, let idolUID = photocard.idolUID, let albumUID = photocard.albumUID else {
            return
        }
        
//        Delete the photocard in the market collection
        let photocardDocInMarket = self.database.collection("market").document(photocardUID)
        
        photocardDocInMarket.delete { error in
            if let error = error {
                print("Error deleting photocardDocInMarket: \(error)")
            } else {
                print("photocardDocInMarket deleted successfully")
            }
        }
       
//        Delete the photocard in the photocards collection, user-photocard collections and the nested group, idol, album collection tree
        let photocardDoc = self.database.collection("photocards").document(photocardUID)
        
        let photocardDocInUser = self.database.collection("users").document(userUID).collection("photocards").document(photocardUID)
        
        let photocardDocInNest = self.database.collection("groups").document(groupUID).collection("idols").document(idolUID).collection("albums").document(albumUID).collection("photocards").document(photocardUID)
        
        photocardDoc.delete { error in
            if let error = error {
                print("Error deleting photocardDoc: \(error)")
            } else {
                print("photocardDoc deleted successfully")
            }
        }

        photocardDocInUser.delete { error in
            if let error = error {
                print("Error deleting photocardDocInUser: \(error)")
            } else {
                print("photocardDocInUser deleted successfully")
            }
        }

        photocardDocInNest.delete { error in
            if let error = error {
                print("Error deleting photocardDocInNest: \(error)")
            } else {
                print("photocardDocInNest deleted successfully")
            }
        }
        
//        Obtain the file name of the image in local storage and firebase storage
        let filename = "/\(photocardUID).jpg"
        guard let photocardImageRef = imageRef?.child(filename) else {
            return
        }
        
//        Remove the image from firebase storage
        photocardImageRef.delete { error in
            if let error = error {
                print("Error deleting file: \(error)")
            } else {
                print("File deleted successfully from firebase storage")
            }
        }
        
//        Remove the image locally
        removeImageData(filename: filename)
        
//        Remove all of the photocards in the user's current portfolio
        if let index = self.allPhotocardsForCurrentUser.firstIndex(where: { $0.photocardUID == photocardUID }) {
            self.allPhotocardsForCurrentUser.remove(at: index)
        }
 
    }
    
//    MARK: Photocard modification (favourite status & image)
    
//    Change whether the photocard is favourited or not
    func changeFavourite(_ photocard: Photocard, _ bool: Bool) {
        
        
        
//        Change photocard favourite status
        photocard.favourite = bool
        
//        Obtain the user-photocard collection reference
        let userPhotocardsRef = self.database.collection("users").document(currentUser!.uid).collection("photocards").document(photocard.photocardUID!)
        
//        Update this document with the favourite status
        userPhotocardsRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching sale listings: \(error.localizedDescription)")
            } else {
                if let document = document, document.exists {
                    // Document exists, so you can access its data
                    guard let data = document.data() else {
                        return
                    }
                    
                    if let photocardRef = data["photocard_ref"] as? DocumentReference {
                        photocardRef.updateData(["favourite": bool])
                    }
                    
//                    Ensure to update the profile page
                    self.setupProfileSettingsListener()
                    
                    
                }
            }
        }
    }

//    Change the image of the photocard
    func changePhotocardImage(_ photocard: Photocard, _ image: UIImage) {
        
//        Change the image of the photocard directly
        photocard.image = image
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        guard let photocardUID = photocard.photocardUID else {
            return
        }
        
//        Obtain the image file name
        let filename = "/\(photocardUID).jpg"
        
//        Obtain the image reference on Firebase Storage
        let newImageRef = imageRef?.child(filename)
        
//        Upload the new image (replace the old one)
        let uploadTask = newImageRef?.putData(data, metadata: metadata) { (metadata, error) in
            guard let metadata = metadata, error == nil else {
                return
            }
        }
        
//        Save image locally
        saveImageData(filename: filename, imageData: data)
        
//        Update use sales listings and portfolio to reflect change photo
        setupUserSaleListingListener()
        setupUserPhotocardListener()
    
    }
    
    // MARK: Purchasing, creating and deleting sale listings
    
//    Purchase a photoard for the current user
    func purchasePhotocard(_ saleListing: SaleListing) {
        
//        First, delete the sale listing
        deleteSaleListing(saleListing)
        
        let photocard = saleListing.photocard
        
        guard let photocardUID = photocard.photocardUID else {
            return
        }
        
//        Obtain the photocard document reference and the user document refernce
        let photocardRef = self.database.collection("photocards").document(photocardUID)
        
        let currentUserRef = self.database.collection("users").document(currentUser!.uid)
        
//        Obtain the user document
        currentUserRef.getDocument{ (document,error) in
            
//            Error handling
            if let error = error {
                print("Error getting photocard document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("User document does not exist")
                return
            }
            
            // Extract data from the photocard document
            guard let userData = document.data() else {
                return
            }
            
            let displayName = userData["name"] as! String
            
//            Change the photocard document to point to the buyer (current user)
            photocardRef.setData([
                "user": self.currentUser?.email,
                "user_display_name": displayName,
                "user_uid": self.currentUser?.uid,
                "favourite": false
            ], mergeFields: ["user","user_display_name","user_uid","favourite"])
            
//            Updte the photocard information and add to the current user's portfolio
            photocard.userEmail = self.currentUser?.email
            photocard.userUID = self.currentUser?.uid
            photocard.userName = displayName
            photocard.favourite = false
            
            self.allPhotocardsForCurrentUser.append(photocard)
            
//            Update the portfolio page to reflect the new photocard added
            self.listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.userPhotocard || listener.listenerType == ListenerType.all {
                    listener.onUserPhotocardChange(change: .update, allPhotocards: self.allPhotocardsForCurrentUser)
                }
            }
        }
        
//        Add the photocard to the user-photocards collection
        let currentUserPhotocardsRef = currentUserRef.collection("photocards")
        
        currentUserPhotocardsRef.document(photocardRef.documentID).setData([
            "photocard_ref": photocardRef
        ])
        
//        Remove the photocard from the old user-photocards collection
        guard let oldUserUID = photocard.userUID else {
            return
        }
        
        let oldUserPhotocardDoc = self.database.collection("users").document(oldUserUID).collection("photocards").document(photocardRef.documentID)
        
        oldUserPhotocardDoc.delete { error in
            if let error = error {
                print("Error deleting photocard from previous user: \(error)")
            } else {
                print("photocard from previous user deleted successfully")
            }
        }
    
    }

//    Delete the sale listing from the sell/buy market
    func deleteSaleListing(_ saleListing: SaleListing) {
        
        guard let photocardUID = saleListing.photocard.photocardUID, let userUID = saleListing.photocard.userUID else {
            return
        }
        
//        Obtain the sale listing document reference in the market collection
        let saleListingDoc = self.database.collection("market").document(photocardUID)
        
//        Obtain the sale listing document reference in the user-photocard on sale collection
        let salelistingDocInUser = self.database.collection("users").document(userUID).collection("photocards_on_sale").document(photocardUID)
        
//        Delete the sale listing document
        saleListingDoc.delete { error in
            
//      Remove the sale listing from the buy market
            var i = 0
            for buyMarketListing in self.allBuyMarketSaleListings {
                if buyMarketListing.photocard.photocardUID == saleListing.photocard.photocardUID {
                    self.allBuyMarketSaleListings.remove(at: i)
                    break
                }
                i = i + 1
            }
            
//            Update the buy market to reflect the removed sale listing
            self.listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.buyMarket || listener.listenerType == ListenerType.all {
                    listener.onBuyMarketChange(change: .update, allSaleListings: self.allBuyMarketSaleListings)
                }
            }
            
            
            
            
        }

//        Delete the sale listing documentin the user-photocard on sale collection
        salelistingDocInUser.delete { error in
            if let error = error {
                print("Error deleting salelistingDocInUser: \(error)")
            } else {
                print("salelistingDocInUser deleted successfully")
            }
        }
        
//        Delete the sale listing from the current user's sell market
        if let index = self.allSaleListingsForCurrentUser.firstIndex(where: { $0.photocard.photocardUID == saleListing.photocard.photocardUID }) {
            self.allSaleListingsForCurrentUser.remove(at: index)
            
//            Update the sell market page to reflect the updated sell market without the newly deleted sale listing
            self.listeners.invoke { (listener) in
               
                if listener.listenerType == ListenerType.userSales || listener.listenerType == ListenerType.all {
                    listener.onUserSaleListingChange(change: .update, allSaleListings: self.allSaleListingsForCurrentUser)
                }
                
            }
        }
        
    }
    
//    Method to create a sale listing and add it to the system
    func addSaleListing(_ photocard: Photocard, _ price: Int, _ location: LocationAnnotation, _ condition: Int) {
        
//        Obtain a reference to the market collection
        let marketRef = self.database.collection("market")
        
        guard let photocardUID = photocard.photocardUID else {
            return
        }

//        This is where the new sale listing will be stored
        let newSaleListingRef = marketRef.document(photocardUID)
        
//        Get the photocard reference
        let photocardRef = self.database.collection("photocards").document(photocardUID)
        
        let dateString = self.getCurrentDateAsString()
        guard let date = self.getDateFromString(dateString: dateString) else {
            return
        }
        
//        Create the new sale listing, storing it into the market collection
        newSaleListingRef.setData([
            "photocard_ref": photocardRef,
            "price": price,
            "location": location.title,
            "location_lat": NSNumber(value: location.coordinate.latitude),
            "location_long": NSNumber(value: location.coordinate.longitude),
            "condition": condition,
            "date": dateString
        ])
        
//        Also add a reference to the sale listing in the user-photocards on sale collection
        let userRef = database.collection("users").document(currentUser!.uid).collection("photocards_on_sale")
        
        userRef.document(photocardUID).setData([
            "sale_listing_ref": newSaleListingRef
        ])
        
//        Create the new sale listing
        let newSaleListing = SaleListing(photocard,price,location,condition,date)
        
//        Remove any sale listings for the same photocard if it exists
        if let index = self.allSaleListingsForCurrentUser.firstIndex(where: { $0.photocard.photocardUID == photocard.photocardUID }) {
            self.allSaleListingsForCurrentUser.remove(at: index)
        }

//        Add the sale listing to the user's sell market
        self.allSaleListingsForCurrentUser.append(newSaleListing)

    }
    
    // MARK: Adding a bias idol/group for the current user
    
//    Add the favourite group to the user's profile
    func addFavGroup(_ group: Group) {
//        Get the groups collection
        let groupRef = database.collection("groups")
        let groupUID = group.name.lowercased()
        
        var documentGroupRef = groupRef.document(groupUID)
        
        //        This checks if the group already exists as a document or not. If it doesn't, create one
        documentGroupRef.getDocument{ (document, error) in
            if let document = document, document.exists {
                print("document already exists")
            } else if let error = error {
                print("error in getting document")
            } else {
                groupRef.document(groupUID).setData([
                    "name": group.name
                ])
                
                        
            }
        }
        
//        Set the favourite group for the current user
        self.favGroup = GroupSingle(name: group.name)
        
        
//        Update the users favourite group on firebase
        let userRef = database.collection("users").document(currentUser!.uid)
        
        userRef.setData([
            "fav_group_ref": documentGroupRef
        ], mergeFields: ["fav_group_ref"])
        
        
    }
    
    
    //    Add the favourite idol to the user's profile
    func addFavIdol(_ idol: Idol) {
        
        //        Get the groups collection
        let groupRef = database.collection("groups")
        let groupUID = idol.group.name.lowercased()
        
        var documentGroupRef = groupRef.document(groupUID)
        
        //        This checks if the group already exists as a document or not. If it doesn't, create one
        documentGroupRef.getDocument{ (document, error) in
            if let document = document, document.exists {
                print("document already exists")
            } else if let error = error {
                print("error in getting document")
            } else {
                groupRef.document(groupUID).setData([
                    "name": idol.group.name
                ])
                

                        
            }
        }
        
        //        Get the idols collection
        let idolRef = self.database.collection("groups").document(groupUID).collection("idols")
        
        let idolUID = idol.name.lowercased()
        
        var documentIdolRef = idolRef.document(idolUID)
        
        //        This checks if the idol already exists as a document or not. If it doesn't, create one
        documentIdolRef.getDocument{ (document, error) in
            if let document = document, document.exists {
                print("document already exists")
            } else if let error = error {
                print("error in getting document")
            } else {
                idolRef.document(idolUID).setData([
                    "name": idol.name
                ])

                        
            }
        }
        
        //        Set the favourite idol for the current user
        self.favIdol = IdolSingleGroup(name: idol.name, group: idol.group.name)
        
        //        Update the users favourite idol on firebase
        let userRef = database.collection("users").document(currentUser!.uid)
        
        userRef.setData([
            "fav_idol_ref": documentIdolRef
        ], mergeFields: ["fav_idol_ref"])
    }
    
//    Reset the user's idol bias to nil
    func clearBiasIdol() {
    
        favIdol = nil
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
        //        Remove idol reference and update the profile view controller
        let documentRef = database.collection("users").document(currentUserUID)
        
        documentRef.updateData([
            "fav_idol_ref": FieldValue.delete()
        ]){ error in
            self.listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                    listener.onFavIdolChange(change: .update, idol: self.favIdol)
                }
            }
        }
    }
    
    //    Reset the user's group bias to nil
    func clearBiasGroup() {
        
        favGroup = nil
        
        
        guard let currentUserUID = currentUser?.uid else {
            return
        }
        
//        Remove group reference and update the profile view controller
        let documentRef = database.collection("users").document(currentUserUID)
        
        documentRef.updateData([
            "fav_group_ref": FieldValue.delete()
        ]){ error in
            self.listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.profile || listener.listenerType == ListenerType.all {
                    listener.onFavGroupChange(change: .update, group: self.favGroup)
                }
            }
        }
    }
    
// MARK: Miscellaneous methods (helper functions)
    
//    Save the image locally
    func saveImageData(filename: String, imageData: Data) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        do {
            try imageData.write(to: fileURL)
        } catch {
            print("Error writing file: \(error.localizedDescription)")
        }
    }
    
//    Remove the image locally
    func removeImageData(filename: String) {
        print("removing image \(filename) locally...")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("File \(filename) removed locally successfully")
        } catch {
            print("Error removing file \(filename) locally: \(error.localizedDescription)")
        }
    }
    
//    Obtain the current date as a sting
    func getCurrentDateAsString() -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
        let currentDate = Date()
        
        let dateString = dateFormatter.string(from: currentDate)
        
        return dateString
    }
    
//    Obtain a specified date as a string
    func getDateAsString(date: Date) -> String {

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        

        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }

//    Obtain the date from a string
    func getDateFromString(dateString: String) -> Date? {
        
        let dateFormatter = DateFormatter()
       
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = dateFormatter.date(from: dateString) {
            return date
        } else {
            return nil
        }
    }
}
