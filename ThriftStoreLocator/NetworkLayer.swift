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
    var favoritesArrayOfDicts = [[String: Any]]()
    var storesArrayOfDicts = [[String: Any]]()
    
    func removeFavorite(store: Store, forUser user: String, networkLayerRemoveFavUpdater: () -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        let userRef = dbFavoritesRef!.child(user)
        if let stateStr = store.state {
            let stateRef = userRef.child(stateStr)
            if let countyStr = store.county {
                let countyRef = stateRef.child(countyStr.lowercased())
                let storeIdStr = (store.storeId?.stringValue)!
                let storeIdRef = countyRef.child(storeIdStr)
                storeIdRef.removeValue()
            }
        }
        networkLayerRemoveFavUpdater()
    }
    
    func postFavorite(store: Store, forUser user: String, networkLayerPostFavUpdater: () -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        
        // Set json user uid key
        let userRef = dbFavoritesRef!.child(user)
        
        // Set state key
        if let storeState = store.state {
            let storeStateRef = userRef.child(storeState)
            
            // Set county key
            if let storeCounty = store.county {
                let storeCountyStr = storeCounty.lowercased()
                let storeCountyRef = storeStateRef.child(storeCountyStr)
                
                // Set store id key
                if let storeId = store.storeId {
                    let storeIdRef = storeCountyRef.child(storeId.stringValue)
                    storeIdRef.setValue(storeId)
                }
            }
        }
        
        networkLayerPostFavUpdater()
    }
    
    func loadFavoritesFromServer(forUser user: String, networkLayerLoadFavoritesUpdater: @escaping ([[String: Any]]) -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        
        self.favoritesArrayOfDicts.removeAll()
        
        let urlString = firebaseFavoritesBaseURL.replacingOccurrences(of: "<QUERY>", with: user)
        
        // First: Do a rest GET to get storeId references to all user favorites
        Alamofire.request(urlString, method: .get).validate()
            
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                    
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    print(json)
                    
                    for (state, subJson):(String, JSON) in json {
                        
                        for (county, subSubJson):(String, JSON) in subJson {
                            
                            for (storeId, _):(String, JSON) in subSubJson {
                                
                                var itemDict = [String: String]()
                                
                                itemDict["state"] = state
                                itemDict["county"] = county
                                itemDict["storeId"] = storeId
                                
                                strongSelf.favoritesArrayOfDicts.append(itemDict as [String: Any])
                            }
                        }
                    }
                    
                    // Next: Use firebase event observer to load favorite stores based on references above and pass back to model manager
                    strongSelf.storesArrayOfDicts.removeAll()
                    
                    let dbStoresRef = FIRDatabase.database().reference(withPath: "thriftstores")
                    
                    var favoritesCount = strongSelf.favoritesArrayOfDicts.count
                    
                    if favoritesCount <= 0 {
                        // No favorites, return
                        networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts)
                        return
                    }
                    
                    for favorite in strongSelf.favoritesArrayOfDicts {
                        
                        if let state = favorite["state"] {
                            let stateRef = dbStoresRef.child(state as! String)
                            
                            if let county = favorite["county"] {
                                let countyStr = (county as! String).lowercased()
                                let countyRef = stateRef.child(countyStr)
                                
                                if let storeId = favorite["storeId"] {
                                    let storeIdRef = countyRef.child(storeId as! String)
                                    
                                    storeIdRef.observeSingleEvent(of: .value, with: { (snapshot) in
                                        
                                        if let value = snapshot.value as? NSDictionary {
                                        
                                            var itemDict = [String: String]()
                                            
                                            itemDict["name"] = value["bizName"] as? String
                                            itemDict["storeId"] = String(describing: value["bizID"] as! Int64)
                                            itemDict["categoryMain"] = value["bizCat"] as? String
                                            itemDict["categorySub"] = value["bizCatSub"] as? String
                                            itemDict["address"] = value["bizAddr"] as? String
                                            itemDict["city"] = value["bizCity"] as? String
                                            itemDict["state"] = value["bizState"] as? String
                                            itemDict["zip"] = value["bizZip"] as? String
                                            itemDict["phone"] = value["bizPhone"] as? String
                                            itemDict["email"] = value["bizEmail"] as? String
                                            itemDict["website"] = value["bizURL"] as? String
                                            itemDict["locLat"] = String(describing: value["locLat"] as! Double)
                                            itemDict["locLong"] = String(describing: value["locLong"] as! Double)
                                            itemDict["county"] = value["locCounty"] as? String
                                            
                                            strongSelf.storesArrayOfDicts.append(itemDict as [String: Any])
                                            
                                            favoritesCount -= 1
                                            
                                            if favoritesCount <= 0 {
                                                networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts)
                                            }
                                        }
                                        
                                    }) { (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                            }
                        }
                    }
                    
                case .failure(let error):
                    // TODO - Proper error handling for Alamofire request
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
                        
                        var itemDict = [String: String]()
                        
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
                        
                        strongSelf.storesArrayOfDicts.append(itemDict as [String: Any])
                    }
                    
                    networkLayerStoreUpdater(strongSelf.storesArrayOfDicts)
                
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
        })
    }
}
