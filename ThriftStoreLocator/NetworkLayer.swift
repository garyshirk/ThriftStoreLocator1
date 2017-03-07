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
private let baseURL = "https://jsonplaceholder.typicode.com/todos"

class NetworkLayer {
    
    var storesArrayOfDicts = [[String:String]]() // Array of Dictionaries
    
    func loadStoresFromServer(modelManagerUpdater: @escaping ([[String:String]]) -> Void) {
        
        Alamofire.request(baseURL, method: .get).validate()
            
            // TODO - Using [weak self] here; is it required?
            .responseJSON(completionHandler: { [weak self] response in
                
                guard let strongSelf = self else { return }
                
                switch response.result {
                
                case .success(let value):
                    
                    let json = JSON(value)
                    
                    print("JSON: \(json)")
                    
                    if let jsonArray = json.array {
                        
                        for item in jsonArray {
                            if let jsonDict = item.dictionary {
                                
                                var itemDict = [String:String]()
                                itemDict["name"] = jsonDict["title"]?.stringValue
                                itemDict["storeId"] = jsonDict["id"]?.stringValue
                                strongSelf.storesArrayOfDicts.append(itemDict)
                            }
                        }
                    }
                    
                    print("Test stores loaded from REST server")
                    modelManagerUpdater(strongSelf.storesArrayOfDicts)
                
                case .failure(let error):
                    // TODO - Proper error handling
                    print(error)
                }
            })
    }

}
