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
private let firebaseThriftStoreBaseURL = "https://thrift-store-locator.firebaseio.com/thriftstores/<COUNTY>.json?auth=APnqdk7uneubbRfzoOT2E0NnRDKurz36tW15gOcA"
private let locationInfoBaseURL = "http://maps.googleapis.com/maps/api/geocode/json?address=<location>&sensor=false"


class NetworkLayer {
    
    var rootRef = FIRDatabase.database().reference()
    
    var locationDict = [String:Any]()
    
    var storesArrayOfDicts = [[String:Any]]() // Array of Dictionaries
    
    
    
    func getLocationInfo(forSearchStr: String, modelManagerLocationUpdater: @escaping ([String:Any]) -> Void) {
        
        let urlString = locationInfoBaseURL.replacingOccurrences(of: "<location>", with: forSearchStr)
        
        Alamofire.request(urlString, method: .get).validate()
            
            // TODO - Using [weak self] here; is it required?
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                    
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    if strongSelf.processLocationJSON(json: json) {
                        modelManagerLocationUpdater(strongSelf.locationDict)
                    } else {
                        // TODO - Error occurred processing Json
                        // For now, send empty dictionary back to StoresViewModel and let him handle it
                        print("Error occurred when attempting to process JSON location info")
                        modelManagerLocationUpdater(strongSelf.locationDict)
                    }
                    
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
            })
    }
    
    func loadStoresFromServer(forCounty county: String, modelManagerStoreUpdater: @escaping ([[String:Any]]) -> Void) {
        
        storesArrayOfDicts.removeAll()
        
       // let urlString = "\(djangoThriftStoreBaseURL)\(filterString)"
        
        let urlString = firebaseThriftStoreBaseURL.replacingOccurrences(of: "<COUNTY>", with: county)
        
        
        
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
                    
                    modelManagerStoreUpdater(strongSelf.storesArrayOfDicts)
                
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
            })
    }
    
    func processLocationJSON(json: JSON) -> Bool {
        
        if json["status"].stringValue != "OK" {
            self.locationDict["error"] = "Error Google api json location info returned not OK"
            return false
        }
        
        if let json = json["results"].array?[0] {
            
            for (index, subJson):(String, JSON) in json {
                
                if index == "geometry" {
                    
                    // Get the lat and long locations
                    self.locationDict["lat"] = (subJson["location"])["lat"].stringValue
                    self.locationDict["long"] = (subJson["location"])["lng"].stringValue
                
                
                } else if index == "formatted_address" {
                    
                    // Get the formatted address
                    self.locationDict["fomatted_address"] = json["formatted_address"].stringValue
                    
                } else if index == "address_components" {
                    
                    // Get address, city, zip, country information
                    for (_, addrJson): (String, JSON) in subJson {
                        
                        
                        if let types = addrJson["types"].arrayObject {
                            
                            for typeValue in types {
                                
                                let type = typeValue as! String
                                
                                if type == "country" {
                                    
                                    // Make sure country type is US
                                    if addrJson["short_name"].stringValue != "US" {
                                        self.locationDict["error"] = "Search result outside US"
                                        return false
                                    }
                                
                                } else if type == "administrative_area_level_1" {
                                    
                                    // Get the state
                                    self.locationDict["state"] = addrJson["short_name"].stringValue
                                    
                                } else if type == "postal_code" {
                                    
                                    // Get the zip code if available
                                    self.locationDict["zip"] = addrJson["short_name"].stringValue
                                
                                } else if type == "locality" {
                                    
                                    // Get the city
                                    self.locationDict["city"] = addrJson["long_name"].stringValue
                                }
                            }
                        }
                    }
                }
            }
        }
        
//        print("LOCATION DICT")
//        print(locationDict["lat"] as! String)
//        print(locationDict["long"] as! String)
//        print(locationDict["city"] as! String)
//        print(locationDict["state"] as! String)
//        if let zip = locationDict["zip"] {
//            print((zip as! String))
//        }
        
        self.locationDict["error"] = ""
        
        return true
    }
}
