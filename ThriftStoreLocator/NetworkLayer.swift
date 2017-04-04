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
    var storesArrayOfDicts = [[String:Any]]() // Array of Dictionaries
    
    
    func loadStoresFromServer(forCounty county: String, modelManagerStoreUpdater: @escaping ([[String:Any]]) -> Void) {
        
        self.storesArrayOfDicts.removeAll()
        
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
}
