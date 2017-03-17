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

// TODO - constants should use pattern for constants (struct or enum)
private let thriftStoreBaseURL = "http://localhost:8000/thriftstores/"
private let locationInfoBaseURL = "http://maps.googleapis.com/maps/api/geocode/json?address=<location>&sensor=false"

class NetworkLayer {
    
    var isLoadingLocal = false
    
    var locationDict = [String:Any]()
    
    var storesArrayOfDicts = [[String:Any]]() // Array of Dictionaries
    
    func getLocationInfo(forSearchStr: String, modelManagerLocationUpdater: @escaping ([String:Any]) -> Void) {
        
        // DEBUG
        let urlString = locationInfoBaseURL.replacingOccurrences(of: "<location>", with: forSearchStr)
        //let urlString = locationInfoBaseURL
        
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
    
    func loadStoresFromServer(filterString: String, modelManagerStoreUpdater: @escaping ([[String:Any]]) -> Void) {
        
        // DEBUG
        if isLoadingLocal {
            loadStoresLocally()
            modelManagerStoreUpdater(storesArrayOfDicts)
            return
        }
        
        storesArrayOfDicts.removeAll()
        
        let urlString = "\(thriftStoreBaseURL)\(filterString)"
        
        
        Alamofire.request(urlString, method: .get).validate()
            
            // TODO - Using [weak self] here; is it required?
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    if let jsonArray = json.array {
                        
                        for item in jsonArray {
                            if let jsonDict = item.dictionary {
                                
                                var itemDict = [String:String]()
                                
                                itemDict["name"] = jsonDict["bizName"]?.stringValue
                                itemDict["storeId"] = jsonDict["bizID"]?.stringValue
                                itemDict["categoryMain"] = jsonDict["bizCat"]?.stringValue
                                itemDict["categorySub"] = jsonDict["bizCatSub"]?.stringValue
                                itemDict["address"] = jsonDict["bizAddr"]?.stringValue
                                itemDict["city"] = jsonDict["bizCity"]?.stringValue
                                itemDict["state"] = jsonDict["bizState"]?.stringValue
                                itemDict["zip"] = jsonDict["bizZip"]?.stringValue
                                itemDict["phone"] = jsonDict["bizPhone"]?.stringValue
                                itemDict["email"] = jsonDict["bizEmail"]?.stringValue
                                itemDict["website"] = jsonDict["bizURL"]?.stringValue
                                itemDict["locLat"] = jsonDict["locLat"]?.stringValue
                                itemDict["locLong"] = jsonDict["locLong"]?.stringValue
                                itemDict["county"] = jsonDict["locCounty"]?.stringValue
                                
                                strongSelf.storesArrayOfDicts.append(itemDict as [String : Any])
                            }
                        }
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
    
    // FOR DEBUG
    func loadStoresLocally() {
        
        let storeDict1  = [
            "name": "Goodwill Algonquin",
            "storeId": "1",
            "address": "1430 E Algonquin Rd",
            "city": "Algonquin",
            "state": "IL",
            "zip": "60102",
            "phone": "630-772-1345",
            "email": "",
            "website": "",
            "locLat": "42.160150",
            "locLong": "-88.273972",
        ] as [String : Any]
        
        storesArrayOfDicts.append(storeDict1)
        
        let storeDict2  = [
            "name": "Goodwill Crystal Lake",
            "storeId": "2",
            "address": "1016 Central Park Dr",
            "city": "Crystal Lake",
            "state": "IL",
            "zip": "60014",
            "phone": "630-676-1345",
            "email": "",
            "website": "",
            "locLat": "42.211024",
            "locLong": "-88.283469",
            ] as [String : Any]
        
        storesArrayOfDicts.append(storeDict2)
        
        let storeDict3  = [
            "name": "Goodwill Carpentersville",
            "storeId": "3",
            "address": "7777 Miller Rd",
            "city": "Carpentersville",
            "state": "IL",
            "zip": "60110",
            "phone": "630-676-1345",
            "email": "",
            "website": "",
            "locLat": "42.121406",
            "locLong": "-88.339040",
            ] as [String : Any]
        
        storesArrayOfDicts.append(storeDict3)
    }
}
