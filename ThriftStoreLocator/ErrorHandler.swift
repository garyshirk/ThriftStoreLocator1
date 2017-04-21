//
//  ErrorHandler.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 4/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import Foundation
import UIKit

enum ErrorType: Equatable {
    case none
    case serverError(String)
    case serverFavPost(String)
    case serverFavDelete(String)
    case coreDataFetch(String)
    case coreDataSave(String)
    case coreDataDelete(String)
    case loginError(String)
    case loginDefault(String)
    case regWeakPassword(String)
    case regInvalidEmail(String)
    case regExistingUser(String)
    case regUnknown(String)
    case anonymousLoginError(String)
}

enum ErrorTitle {
    static let genericTitle = "Error"
}

enum UserErrorMessage {
    static let unknown = "An error occurred while accessing thrift stores, please try again later"
    static let dataAccess = "There was an error accessing thrift stores, please try again later"
    static let postFav = "There was an error saving your favorite"
    static let deleteFav = "There was an error removing your favorite"
    static let login = "Incorrect username or password, please try again"
    static let loginDefault = "There was an error signing in to the app. Ensure email address is valid and password is at least 6 characters. If still getting error please try again later"
    static let loginWeakPw = "Password must be at least 6 characters"
    static let loginInvalidEm = "The email address entered is invalid, please try again"
    static let loginExistingEm = "The email address is already in use"
    
}

enum DebugErrorMessage {
    static let unknownError = "An unknown error occurred in errorType switch, should never get here"
    static let firebaseDbAccessError = "Error when attempting to access firebase references and/or json keys"
    static let coreDataFetch = "Error fetching from core data"
    static let coreDataSave = "Error when attempting to save core data objects"
    static let coreDataDelete = "Error when attempting to delete core data objects"
}

private let _sharedManager = ErrorHandler()

class ErrorHandler {
    
    class var sharedManager: ErrorHandler {
        return _sharedManager
    }
    
    func handleError(ofType errorType: ErrorType) -> UIAlertController? {
        
        // Note: For now not displaying error dialog if error caused or potentially caused by
        // adding or removing favorites, because when that happens the main VC is not always
        // attached and in some cases presenting dialog from main VC fails.
        // This is an implementation issue
        var displayErrorDialog: Bool!
        
        let displayTitle = ErrorTitle.genericTitle
        var displayMsg: String
        
        switch errorType {
            
        case .serverError(let debugMsg):
            displayMsg = UserErrorMessage.dataAccess
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .serverFavPost(let debugMsg):
            displayMsg = UserErrorMessage.postFav
            displayErrorDialog = false
            Logger.print(debugMsg)
            
        case .serverFavDelete(let debugMsg):
            displayMsg = UserErrorMessage.deleteFav
            displayErrorDialog = false
            Logger.print(debugMsg)
            
        case .coreDataFetch(let debugMsg):
            displayMsg = UserErrorMessage.dataAccess
            displayErrorDialog = false
            Logger.print(debugMsg)
            
        case .coreDataSave(let debugMsg):
            displayMsg = UserErrorMessage.dataAccess
            displayErrorDialog = false
            Logger.print(debugMsg)
            
        case .coreDataDelete(let debugMsg):
            displayMsg = UserErrorMessage.dataAccess
            displayErrorDialog = false
            Logger.print(debugMsg)
            
        case .loginError(let debugMsg):
            displayMsg = UserErrorMessage.login
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .loginDefault(let debugMsg):
            displayMsg = UserErrorMessage.loginDefault
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .regExistingUser(let debugMsg):
            displayMsg = UserErrorMessage.loginExistingEm
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .regInvalidEmail(let debugMsg):
            displayMsg = UserErrorMessage.loginInvalidEm
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .regWeakPassword(let debugMsg):
            displayMsg = UserErrorMessage.loginWeakPw
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .regUnknown(let debugMsg):
            displayMsg = UserErrorMessage.loginDefault
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        case .anonymousLoginError(let debugMsg):
            displayMsg = UserErrorMessage.loginDefault
            displayErrorDialog = true
            Logger.print(debugMsg)
            
        default:
            displayMsg = UserErrorMessage.unknown
            displayErrorDialog = false
            Logger.print(DebugErrorMessage.unknownError)
        }
        
        if displayErrorDialog == true {
            return errorDialog(title: displayTitle, msg: displayMsg)
        } else {
            return nil
        }
    }
    
    func errorDialog(title: String, msg: String) -> UIAlertController? {
        
        let alert = UIAlertController(title: title,
                                      message: msg,
                                      preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Ok",
                               style: .default)
        
        alert.addAction(ok)
        
        return alert
    }
}

extension ErrorType {
    func isNone() -> Bool {
        switch self {
            case .none: return true
            default: return false
        }
    }
}

func ==(lhs: ErrorType, rhs: ErrorType) -> Bool {
    return lhs.isNone()
}
