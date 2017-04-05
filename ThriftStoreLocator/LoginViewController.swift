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

protocol LogInDelegate: class {
    
    func handleUserLoggedIn(via loginType: String)
    
    func getRegistrationType() -> String
    
    func setRegistrationType(with regType: String)
}

enum RegistrationType {
    static let registered = "registered"
    static let firstTimeInApp = "first_time_in_app"
    static let anonymousUser = "anonymous"
    static let regKey = "reg_key"
}

enum LogInType {
    static let isNotLoggedIn = "is_not_logged_in"
    static let facebook = "facebook"
    static let email = "email"
    static let anonymousLogin = "anonymous_login"
}

// TODO add fb App Events after you get login working

class LoginViewController: UITableViewController, UITextFieldDelegate {
    
    weak var logInDelegate: LogInDelegate?
    var fbLoginManager: FBSDKLoginManager?
    var currentUser: User?
    var dict : [String : Any]!
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var maybeRegLaterButton: UIButton!
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        emailTextfield.delegate = self
        passwordTextfield.delegate = self
        
        fbLoginManager = FBSDKLoginManager()
        
        print("Current User in LoginView =======> \(self.currentUser?.uid), \(self.currentUser?.email)")
        
        let regType = logInDelegate?.getRegistrationType()
        if regType == RegistrationType.registered {
            maybeRegLaterButton.isHidden = true
        } else {
            maybeRegLaterButton.setTitle("Maybe later", for: .normal)
            maybeRegLaterButton.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func userNameLoginPressed(_ sender: Any) {
        
        FIRAuth.auth()?.signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { (user, error) in
            
            if error == nil {
                
                print("An existing user: \(user?.email), \(user?.uid) logged back in")
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                self.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                
            } else {
                print("Error existing user attempting to login: \(error)")
            }
        }
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Register",
                                      message: "Register",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { action in
                                        
                                        let emailField = alert.textFields![0]
                                        let passwordField = alert.textFields![1]
                                        
                                        
                                        if let currentUser = FIRAuth.auth()?.currentUser {
                                            
                                            // An anonymous user is registering
                                            if currentUser.isAnonymous {
                                                self.registerAnonymous(currentUser: currentUser, email: emailField.text!, password: passwordField.text!)
                                                
                                            } else {
                                                self.registerNewUser(email: emailField.text!, password: passwordField.text!)
                                            }
                                            
                                        } else {
                                            
                                            // User is registering first time in the app
                                            self.registerNewUser(email: emailField.text!, password: passwordField.text!)
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
    
    
    func registerAnonymous(currentUser: FIRUser, email: String, password: String) {
        
        let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
        currentUser.link(with: credential) { (user, error) in
            if error == nil {
                print("Anonymous user: \(currentUser.uid) successfully linked to new registered user: \(user?.email), \(user?.uid)")
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                self.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                
            } else {
                print("Error linking anonymous user to new registration: \(error)")
            }
        }
    }
    
    func registerNewUser(email: String, password: String) {
        
        FIRAuth.auth()!.createUser(withEmail: email, password: password) { user, error in
            if error == nil {
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                    if error == nil {
                        print("\(user?.email), \(user?.uid) successfully registered first time in app")
                        self.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                    } else {
                        print("Error logging in a newly registered user: \(error)")
                    }
                }
            } else {
                print("Error registering a new user: \(error)")
            }
        }
    }
    
    @IBAction func maybeLaterPressed(_ sender: Any) {
        
        let regType = logInDelegate?.getRegistrationType()
        
        if regType == RegistrationType.firstTimeInApp {
            
            FIRAuth.auth()?.signInAnonymously() { (user, error) in
                if error == nil {
                    print("A new user: \(user?.email), \(user?.uid) was successfully logged in anonymously")
                    self.logInDelegate?.setRegistrationType(with: RegistrationType.anonymousUser)
                    self.logInDelegate?.handleUserLoggedIn(via: (LogInType.anonymousLogin as String))
                } else {
                    print("Error logging in a new user as anonymous: \(error)")
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func fbLoginButtonPressed(_ sender: Any) {
        
        fbLoginManager!.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            
            if (error == nil){
                
                if let current = FBSDKAccessToken.current() {
                    
                    print("Facebook user is logged in")
                    print("Access Token")
                    print("String      : \(current.tokenString)")
                    print("User ID     : \(current.userID)")
                    print("App ID      : \(current.appID)")
                    print("Refresh Date: \(current.refreshDate)")
                }
                
                let fbLoginResult : FBSDKLoginManagerLoginResult = result!
                
                if fbLoginResult.grantedPermissions != nil {
                    
                    if(fbLoginResult.grantedPermissions.contains("email")) {
                        
                        self.getFBUserData()
                        
                        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                        
                        if let currentUser = FIRAuth.auth()?.currentUser {
                            
                            if currentUser.isAnonymous {
                                
                                self.registerAnonymousUserToFacebook(currentUser: currentUser, credential: credential)
                                
                            } else {
                                
                                self.registerNewUserToFacebook(credential: credential)
                            }
                            
                        } else {
                            
                            self.registerNewUserToFacebook(credential: credential)
                        }
                    }
                }
            }
        }
        
    }
    
    
    func registerAnonymousUserToFacebook(currentUser: FIRUser, credential: FIRAuthCredential) {
        
        currentUser.link(with: credential) { (user, error) in
            
            if error == nil {
                
                // TODO - This path needs tested; need new facebook test account
                print("An anonymous user: \(currentUser.email), \(currentUser.uid) was successfully registered with facebook")
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                self.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                
            } else {
                print("Error when anonymous user attempted to login to Facebook: \(error)")
                
                if let errCode = FIRAuthErrorCode(rawValue: error!._code) {
                    
                    switch errCode {
                    case .errorCodeInvalidEmail:
                        print("Invalid email")
                    case .errorCodeEmailAlreadyInUse:
                        print("Email address already in use")
                    case .errorCodeCredentialAlreadyInUse:
                        print("Credential already in use")
                        print("User logged in with a previously used facebook crendential. The anonymouse user credential was ignored: \(currentUser.uid) was successfully registered with facebook")
                        self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                        self.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                    default:
                        print("Create User Error: \(error)")
                    }    
                }
            }
        }
    }
    
    func registerNewUserToFacebook(credential: FIRAuthCredential) {
        
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            
            if error == nil {
                
                print("A new user: \(user?.email), \(user?.uid) was successfully logged in via facebook")
                self.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                self.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                
            } else {
                print("Error when first time user attempted to login via facebook: \(error?.localizedDescription)")
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
