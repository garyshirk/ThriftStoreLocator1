//
//  LoginViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 3/19/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

protocol LogInDelegate {
    
    func handleUserLoggedIn(via loginType:MainViewController.LogInType)
    
    func getRegistrationType() -> String
    
    func setRegistrationType(with regType: String)
}

// TODO add fb App Events after you get login working

class LoginViewController: UIViewController {
    
    var logInDelegate: LogInDelegate?
    var fbLoginManager: FBSDKLoginManager?
    var dict : [String : Any]!
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var maybeRegLaterButton: UIButton!
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        fbLoginManager = FBSDKLoginManager()
        
        let regType = logInDelegate?.getRegistrationType()
        if regType != RegistrationType.registered {
            maybeRegLaterButton.setTitle("Maybe later", for: .normal)
        } else {
            maybeRegLaterButton.setTitle("Cancel", for: .normal)
        }
    }
    
    @IBAction func usernameLoginPressed(_ sender: Any) {
        FIRAuth.auth()?.signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { (user, error) in
            if error == nil {
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                self.logInDelegate?.handleUserLoggedIn(via: MainViewController.LogInType.email)
            } else {
                print("Signin error: \(error)")
            }
        }
    }
    
    // TODO - strongSelf
    @IBAction func registerPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Register",
                                      message: "Register",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { action in
                                
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
           
            FIRAuth.auth()!.createUser(withEmail: emailField.text!,
                                       password: passwordField.text!) { user, error in
                if error == nil {
                    
                    self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                    
                    FIRAuth.auth()?.signIn(withEmail: emailField.text!, password: passwordField.text!) { (user, error) in
                        if error == nil {
                            self.logInDelegate?.handleUserLoggedIn(via: MainViewController.LogInType.email)
                        } else {
                            print("Signin error: \(error)")
                        }
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                        style: .default)
        
        alert.addTextField { textEmail in
            textEmail.placeholder = "Enter your email"
        }
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    @IBAction func maybeLaterPressed(_ sender: Any) {
        
        let regType = logInDelegate?.getRegistrationType()
        if regType == RegistrationType.firstTimeInApp {
            // TODO - Anonymously log in the user
            self.logInDelegate?.setRegistrationType(with: RegistrationType.anonymous)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func fbLoginButtonPressed(_ sender: Any) {
        
        // TODO - strongSelf?
        fbLoginManager!.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if (error == nil){
                
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                
                if let current = FBSDKAccessToken.current() {
                
                    print("Facebook user is logged in")
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
                        
                        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                        
                        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                            if let error = error {
                                print("Firebase signin error: \(error.localizedDescription)")
                                return
                            }
                        }
                        
                        self.logInDelegate?.handleUserLoggedIn(via: MainViewController.LogInType.facebook)
                        
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
                }
            })
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

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextfield {
            passwordTextfield.becomeFirstResponder()
        }
        if textField == passwordTextfield {
            textField.resignFirstResponder()
        }
        return true
    }
}
