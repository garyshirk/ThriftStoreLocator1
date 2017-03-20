//
//  FacebookLoginViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 3/19/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
//import FacebookLogin
//import FacebookCore
import FBSDKLoginKit

protocol FacebookLogInDelegate {
    
    func handleUserLoggedInViaFacebook()
}

// TODO add fb App Events after you get login working

class FacebookLoginViewController: UIViewController {
    
    var logInDelegate: FacebookLogInDelegate?
    
    var fbLoginManager: FBSDKLoginManager?
   
    var dict : [String : Any]!
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        fbLoginManager = FBSDKLoginManager()
        
        if let _ = FBSDKAccessToken.current() {
            print("User is logged in")
            
        } else{
            print("User is logged out")
        }
    }
    
    @IBAction func fbLoginButtonPressed(_ sender: Any) {
        
        // TODO - strongSelf
        fbLoginManager!.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if (error == nil){
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
    
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! [String : AnyObject]
                    print(result!)
                    print(self.dict)
                }
            })
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
