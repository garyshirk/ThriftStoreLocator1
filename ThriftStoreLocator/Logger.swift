//
//  Logger.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/21/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation

struct Logger {
    
    static func releasePrint(_ object: Any) {
        Swift.print(object)
    }
    
    static func print(_ object: Any) {
        #if DEBUG
            Swift.print(object)
        #endif
    }
}
