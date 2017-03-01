//
//  NetworkLayer.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/28/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import Alamofire

private let baseURL = "https://jsonplaceholder.typicode.com/todos"

class NetworkLayer {
    
    func loadStoresFromServer() {
        
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
                let json = response.result.value
                print(json!)
            })
    }


}
