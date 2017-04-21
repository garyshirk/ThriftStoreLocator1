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
private let firebaseThriftStoreBaseURL = "https://thrift-store-locator.firebaseio.com/thriftstores/<QUERY>.json?auth=Oo28wAkZypjeuijFzjxEVhRwvZe6gTUq8dn3RABo"
private let firebaseFavoritesBaseURL = "https://thrift-store-locator.firebaseio.com/favorites/<QUERY>.json?auth=Oo28wAkZypjeuijFzjxEVhRwvZe6gTUq8dn3RABo"
private let locationInfoBaseURL = "http://maps.googleapis.com/maps/api/geocode/json?address=<location>&sensor=false"

class NetworkLayer {
    
    var dbFavoritesRef: FIRDatabaseReference?
    var rootRef = FIRDatabase.database().reference()
    var favoritesArrayOfDicts = [[String: Any]]()
    var storesArrayOfDicts = [[String: Any]]()
    var atLeastOneFoundFavSuccessfullyLoaded: Bool?
    
    func removeFavorite(store: Store, forUser user: String, networkLayerRemoveFavUpdater: @escaping (ErrorType) -> Void) {
        
        var errorType: ErrorType = .none
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        let userRef = dbFavoritesRef!.child(user)
        if let stateStr = store.state {
            let stateRef = userRef.child(stateStr)
            if let countyStr = store.county {
                let countyRef = stateRef.child(countyStr.lowercased())
                let storeIdStr = (store.storeId?.stringValue)!
                let storeIdRef = countyRef.child(storeIdStr)
                storeIdRef.removeValue() { (error, ref) -> Void in
                    if error != nil {
                        errorType = .serverFavDelete(error!.localizedDescription)
                    }
                    networkLayerRemoveFavUpdater(errorType)
                }
            } else {
                errorType = .serverFavDelete(DebugErrorMessage.firebaseDbAccessError)
                networkLayerRemoveFavUpdater(errorType)
            }
        } else {
            errorType = .serverFavDelete(DebugErrorMessage.firebaseDbAccessError)
            networkLayerRemoveFavUpdater(errorType)
        }
    }
    
    func postFavorite(store: Store, forUser user: String, networkLayerPostFavUpdater: @escaping (ErrorType) -> Void) {
        
        var errorType: ErrorType = .none
        
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
                    storeIdRef.setValue(storeId) { (error, ref) -> Void in
                        if error != nil {
                            errorType = .serverFavPost(error!.localizedDescription)
                        }
                        networkLayerPostFavUpdater(errorType)
                    }
                } else {
                    errorType = .serverFavPost(DebugErrorMessage.firebaseDbAccessError)
                    networkLayerPostFavUpdater(errorType)
                }
            } else {
                errorType = .serverFavPost(DebugErrorMessage.firebaseDbAccessError)
                networkLayerPostFavUpdater(errorType)
            }
        } else {
            errorType = .serverFavPost(DebugErrorMessage.firebaseDbAccessError)
            networkLayerPostFavUpdater(errorType)
        }
    }
    
    func loadFavoritesFromServer(forUser user: String, networkLayerLoadFavoritesUpdater: @escaping ([[String: Any]], ErrorType) -> Void) {
        
        dbFavoritesRef = FIRDatabase.database().reference(withPath: "favorites")
        
        self.favoritesArrayOfDicts.removeAll()
        
        let urlString = firebaseFavoritesBaseURL.replacingOccurrences(of: "<QUERY>", with: user)
        
        var errorType: ErrorType = .none
        
        // First: Do a rest GET to get storeId references to all user favorites
        Alamofire.request(urlString, method: .get).validate()
            
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                    
                case .success(let value):
                    
                    let json = JSON(value)
                    
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
                        networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts, ErrorType.none)
                        return
                    } else {
                        strongSelf.atLeastOneFoundFavSuccessfullyLoaded = false
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
                                            
                                            strongSelf.atLeastOneFoundFavSuccessfullyLoaded = true
                                            
                                            if favoritesCount <= 0 {
                                                networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts, ErrorType.none)
                                                strongSelf.storesArrayOfDicts.removeAll()
                                                strongSelf.favoritesArrayOfDicts.removeAll()
                                            }
                                        }
                                        
                                    }) { (error) in
                                        errorType = ErrorType.serverError(error.localizedDescription)
                                        networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts, errorType)
                                    }
                                }
                            }
                        }
                    }
                    if strongSelf.atLeastOneFoundFavSuccessfullyLoaded == false {
                        networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts, ErrorType.none)
                    }
                    
                case .failure(let error):
                    errorType = ErrorType.serverError(error.localizedDescription)
                    networkLayerLoadFavoritesUpdater(strongSelf.storesArrayOfDicts, errorType)
                }
            })
    }
    
    func loadStoresFromServer(forQuery query: String, networkLayerStoreUpdater: @escaping ([[String: Any]], ErrorType) -> Void) {
        
        self.storesArrayOfDicts.removeAll()
        
        var isLoadingByState = false
        if query.range(of: "/") == nil {
            isLoadingByState = true
        }
        
        let urlString = firebaseThriftStoreBaseURL.replacingOccurrences(of: "<QUERY>", with: query)
        
        // Load stores by county
        if isLoadingByState == false {
            
            var errorType: ErrorType = .none
        
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
                        
                        networkLayerStoreUpdater(strongSelf.storesArrayOfDicts, ErrorType.none)
                        
                        strongSelf.storesArrayOfDicts.removeAll()
                    
                    case .failure(let error):
                        errorType = ErrorType.serverError(error.localizedDescription)
                        networkLayerStoreUpdater(strongSelf.storesArrayOfDicts, errorType)
                    }
            })
        
        } else {
            
            // Load stores by state
            var errorType: ErrorType = .none
            
            Alamofire.request(urlString, method: .get).validate()
                
                .responseJSON(completionHandler: { [weak self] response in
                    
                    guard let strongSelf = self else { return }
                    
                    switch response.result {
                        
                    case .success(let value):
                        
                        let json = JSON(value)
                        
                        for (_, countyJson):(String, JSON) in json {
                            
                            for (_, storeJson):(String, JSON) in countyJson {
                            
                                var itemDict = [String: String]()
                                
                                itemDict["name"] = storeJson["bizName"].stringValue
                                itemDict["storeId"] = storeJson["bizID"].stringValue
                                itemDict["categoryMain"] = storeJson["bizCat"].stringValue
                                itemDict["categorySub"] = storeJson["bizCatSub"].stringValue
                                itemDict["address"] = storeJson["bizAddr"].stringValue
                                itemDict["city"] = storeJson["bizCity"].stringValue
                                itemDict["state"] = storeJson["bizState"].stringValue
                                itemDict["zip"] = storeJson["bizZip"].stringValue
                                itemDict["phone"] = storeJson["bizPhone"].stringValue
                                itemDict["email"] = storeJson["bizEmail"].stringValue
                                itemDict["website"] = storeJson["bizURL"].stringValue
                                itemDict["locLat"] = storeJson["locLat"].stringValue
                                itemDict["locLong"] = storeJson["locLong"].stringValue
                                itemDict["county"] = storeJson["locCounty"].stringValue
                                
                                strongSelf.storesArrayOfDicts.append(itemDict as [String: Any])
                            }
                        }
                        
                        networkLayerStoreUpdater(strongSelf.storesArrayOfDicts, ErrorType.none)
                        
                        strongSelf.storesArrayOfDicts.removeAll()
                        
                    case .failure(let error):
                        errorType = ErrorType.serverError(error.localizedDescription)
                        networkLayerStoreUpdater(strongSelf.storesArrayOfDicts, errorType)
                    }
                })
        }
    }
}
