//
//  NetworkLayer.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import FirebaseDatabase

// TODO - constants should use pattern for constants (struct or enum)
private let djangoThriftStoreBaseURL = "http://localhost:8000/thriftstores/"
private let firebaseThriftStoreBaseURL = "https://thrift-store-locator.firebaseio.com/thriftstores/<QUERY>.json?auth=<AUTH-TOKEN>"
private let firebaseFavoritesBaseURL = "https://thrift-store-locator.firebaseio.com/favorites/<QUERY>.json?auth=<AUTH-TOKEN>"
private let locationInfoBaseURL = "http://maps.googleapis.com/maps/api/geocode/json?address=<location>&sensor=false"

var dbFavoritesRef: FIRDatabaseReference?

class NetworkLayer {
    
    var rootRef = FIRDatabase.database().reference()
    var storesArrayOfDicts = [[String:Any]]()
    
    func removeFavorite(store: Store, forUser user: String, networkLayerRemoveFavUpdate: () -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        let userRef = dbFavoritesRef!.child(user)
        let bizIdStr = (store.storeId?.stringValue)!
        let storeIdRef = userRef.child(bizIdStr)
        storeIdRef.removeValue()
        networkLayerRemoveFavUpdate()
    }
    
    func postFavorite(store: Store, forUser user: String, networkLayerPostFavUpdater: () -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        
        // Set user uid key
        let userRef = dbFavoritesRef!.child(user)
        
        // Set bizID key
        let bizIdStr = (store.storeId?.stringValue)!
        let storeIdRef = userRef.child(bizIdStr)
        
        // Set bizID
        let bizIdInt = store.storeId?.intValue
        let bizIdRef = storeIdRef.child("bizID")
        bizIdRef.setValue(bizIdInt)
        
        // Set bizName
        let bizName = store.name
        let bizNameRef = storeIdRef.child("bizName")
        bizNameRef.setValue(bizName)
        
        // Set bizCat
        let bizCat = store.categoryMain ?? ""
        let bizCatRef = storeIdRef.child("bizCat")
        bizCatRef.setValue(bizCat)
        
        // Set bizCatSub
        let bizCatSub = store.categorySub ?? ""
        let bizCatSubRef = storeIdRef.child("bizCatSub")
        bizCatSubRef.setValue(bizCatSub)
        
        // Set bizAddr
        let bizAddr = store.address
        let bizAddrRef = storeIdRef.child("bizAddr")
        bizAddrRef.setValue(bizAddr)
        
        // Set bizCity
        let bizCity = store.city
        let bizCityRef = storeIdRef.child("bizCity")
        bizCityRef.setValue(bizCity)
        
        // Set bizState
        let bizState = store.state
        let bizStateRef = storeIdRef.child("bizState")
        bizStateRef.setValue(bizState)

        // Set bizZip
        let bizZip = store.zip
        let bizZipRef = storeIdRef.child("bizZip")
        bizZipRef.setValue(bizZip)
        
        // Set bizPhone
        let bizPhone = store.phone ?? ""
        let bizPhoneRef = storeIdRef.child("bizPhone")
        bizPhoneRef.setValue(bizPhone)
        
        // Set bizEmail
        let bizEmail = store.email ?? ""
        let bizEmailRef = storeIdRef.child("bizEmail")
        bizEmailRef.setValue(bizEmail)
        
        // Set bizURL
        let bizUrl = store.website ?? ""
        let bizUrlRef = storeIdRef.child("bizURL")
        bizUrlRef.setValue(bizUrl)
        
        // Set bizLat
        let bizLat = store.locLat?.doubleValue
        let bizLatRef = storeIdRef.child("locLat")
        bizLatRef.setValue(bizLat)
        
        // Set bizLong
        let bizLong = store.locLong?.doubleValue
        let bizLongRef = storeIdRef.child("locLong")
        bizLongRef.setValue(bizLong)
        
        // Set bizCounty
        let bizCounty = store.county
        let bizCountyRef = storeIdRef.child("locCounty")
        bizCountyRef.setValue(bizCounty)
        
        networkLayerPostFavUpdater()
    }
    
    func loadFavoritesFromServer(forUser user: String, networkLayerLoadFavoritesUpdater: @escaping ([[String: Any]]) -> Void) {
        
        self.storesArrayOfDicts.removeAll()
        
        let urlString = firebaseFavoritesBaseURL.replacingOccurrences(of: "<QUERY>", with: user)
        
        Alamofire.request(urlString, method: .get).validate()
            
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                    
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    for (_, subJson):(String, JSON) in json {
                        
                        print(subJson)
                        
                        var itemDict = [String:String]()
                        
                        itemDict["name"] = subJson["bizName"].stringValue
                        itemDict["storeId"] = subJson["bizID"].stringValue
                        itemDict["categoryMain"] = subJson["bizCat"].stringValue
                        itemDict["categorySub"] = subJson["bizCatSub"].stringValue
                        itemDict["address"] = subJson["bizAddr"].stringValue
                        itemDict["city"] = subJson["bizCity"].stringValue
                        itemDict["state"] = subJson["bizState"].stringValue
                        itemDict["zip"] = subJson["bizZip"].stringValue
                        itemDict["phone"] = subJson["bizPhone"].stringValue
                        itemDict["email"] = subJson["bizEmail"].stringValue
                        itemDict["website"] = subJson["bizURL"].stringValue
                        itemDict["locLat"] = subJson["locLat"].stringValue
                        itemDict["locLong"] = subJson["locLong"].stringValue
                        itemDict["county"] = subJson["locCounty"].stringValue
                        
                        strongSelf.storesArrayOfDicts.append(itemDict as [String : Any])
                    }
                    
                    networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts)
                    
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
        })
    }
    
    
    func loadStoresFromServer(forQuery query: String, networkLayerStoreUpdater: @escaping ([[String: Any]]) -> Void) {
        
        self.storesArrayOfDicts.removeAll()
        
        let urlString = firebaseThriftStoreBaseURL.replacingOccurrences(of: "<QUERY>", with: query)
        
        Alamofire.request(urlString, method: .get).validate()
            
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    for (_, subJson):(String, JSON) in json {
                        
                        print(subJson)
                        
                        var itemDict = [String:String]()
                        
                        itemDict["name"] = subJson["bizName"].stringValue
                        itemDict["storeId"] = subJson["bizID"].stringValue
                        itemDict["categoryMain"] = subJson["bizCat"].stringValue
                        itemDict["categorySub"] = subJson["bizCatSub"].stringValue
                        itemDict["address"] = subJson["bizAddr"].stringValue
                        itemDict["city"] = subJson["bizCity"].stringValue
                        itemDict["state"] = subJson["bizState"].stringValue
                        itemDict["zip"] = subJson["bizZip"].stringValue
                        itemDict["phone"] = subJson["bizPhone"].stringValue
                        itemDict["email"] = subJson["bizEmail"].stringValue
                        itemDict["website"] = subJson["bizURL"].stringValue
                        itemDict["locLat"] = subJson["locLat"].stringValue
                        itemDict["locLong"] = subJson["locLong"].stringValue
                        itemDict["county"] = subJson["locCounty"].stringValue
                        
                        strongSelf.storesArrayOfDicts.append(itemDict as [String : Any])
                    }
                    
                    networkLayerStoreUpdater(strongSelf.storesArrayOfDicts)
                
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
        })
    }
}
