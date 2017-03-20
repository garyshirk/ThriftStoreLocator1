//
//  FacebookLoginViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 3/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import Firebase

class FacebookLoginViewController: UIViewController, LoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = AccessToken.current {
            // User is logged in, use 'accessToken' here.
        }

        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        view.addSubview(loginButton)
        
        loginButton.delegate = self
        
        
        
        // Extend the code sample "1. Add Facebook Login Button Code"
        // In your viewDidLoad method:
        //loginButton = LoginButton(readPermissions: [ .PublicProfile, .Email, .UserFriends ])
    }
    
    
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            // Handle Firebase ios Auth errors: https://firebase.google.com/docs/auth/ios/errors
            if let error = error {
                print("Error auth to Firebase: \(error.localizedDescription)")
                return
            }
        }
    }
    

    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("Logout delegate called")
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
