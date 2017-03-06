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
    
    var stores: [String] = ["Goodwill", "Salvation Army", "Savers", "Thrift on Main", "Sparrows Nest",
                            "Goodwill Schaumburg", "Goodwill2", "Salvation Army2", "Savers2",
                            "Thrift on Main2", "Sparrows Nest2", "Goodwill Crystal Lake",
                            "Thrift on Main3", "Sparrows Nest3", "Goodwill Carpentersville",
                            "Thrift on Main4", "Sparrows Nest4", "Goodwill Lake Zurich"]
    
    func loadStoresFromServer(loadStores: @escaping ([String]) -> Void) { //([Store]) -> Void) {
        
        Alamofire.request(baseURL, method: .get)
        
            .responseJSON(completionHandler: { response in
                guard response.result.error == nil else {
                    // Error - got no data back
                    print("Error calling GET on baseURL")
                    print(response.result.error!)
                    return
                }
                
                // If did get back data, make sure it's JSON
//                guard let json = response.result.value as? [String: Any] else {
//                    print("Error - response is not JSON")
//                    print("\(response.result.error)")
//                    return
//                }
//                
//                // All ok, get the data
//                guard let title = json["title"] as? String else {
//                    print("Could not find value in json")
//                    return
//                }
//                print("The title is: " + title)
                
                let _ = response.result.value // change _ to json once we start using data retrieved from server
                
                // Mock - return hard coded test stores for now just to make sure vc, model and network layer are connected properly
                loadStores(self.stores)
                
                
                
                //print(json!)
            })
    }


}
