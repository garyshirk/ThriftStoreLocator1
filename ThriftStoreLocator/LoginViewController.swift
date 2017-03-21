//
//  LoginViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 3/19/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
//import FacebookLogin
//import FacebookCore
import FBSDKLoginKit
import Firebase

protocol FacebookLogInDelegate {
    
    func handleUserLoggedInViaFacebook()
}

// TODO add fb App Events after you get login working

class LoginViewController: UIViewController {
    
    var logInDelegate: FacebookLogInDelegate?
    
    var fbLoginManager: FBSDKLoginManager?
   
    var dict : [String : Any]!
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        fbLoginManager = FBSDKLoginManager()
        
        if let _ = FBSDKAccessToken.current() {
            
            
        } else{
            print("User is logged out")
        }
    }
    
    @IBAction func fbLoginButtonPressed(_ sender: Any) {
        
        // TODO - strongSelf
        fbLoginManager!.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if (error == nil){
                
                if let current = FBSDKAccessToken.current() {
                
                    print("User is logged in")
                    print("Access Token")
                    print("String      : \(current.tokenString)")
                    print("User ID     : \(current.userID)")
                    print("App ID      : \(current.appID)")
                    print("Refresh Date: \(current.refreshDate)")
                }
                
                let fbloginresult : FBSDKLoginManagerLoginResult = result!
                if fbloginresult.grantedPermissions != nil {
                    if(fbloginresult.grantedPermissions.contains("email"))
                    {
                        self.getFBUserData()
                        self.logInDelegate?.handleUserLoggedInViaFacebook()
                        print("FB logged in with email permisions")
                    }
                }
            }
        }
    }
    
    // TODO - StrongSelf?
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil) {
                    self.dict = result as! [String : AnyObject]
                    print("RESULT: \(result!)")
                    print("DICT: \(self.dict)")
                    
                    //imageView.downloadedFrom(link: "http://www.apple.com/euro/ios/ios8/a/generic/images/og.png")
                    
                    self.signInToFirebase()
                }
            })
        }
    }
    
    func signInToFirebase() {
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            // ...
            if let error = error {
                print("Firebase signin error: \(error.localizedDescription)")
                return
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
