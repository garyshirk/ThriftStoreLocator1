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

class LoginViewController: UITableViewController, UITextFieldDelegate {
    
    weak var logInDelegate: LogInDelegate?
    var fbLoginManager: FBSDKLoginManager?
    var dict : [String : Any]!
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var maybeRegLaterButton: UIButton!
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        emailTextfield.delegate = self
        emailTextfield.keyboardType = UIKeyboardType.emailAddress
        passwordTextfield.delegate = self
        
        fbLoginManager = FBSDKLoginManager()
        
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
    
    func handleError(errorType: ErrorType) {
        let errorHandler = ErrorHandler.sharedManager
        if let errorAlert = errorHandler.handleError(ofType: errorType) {
            self.present(errorAlert, animated: true, completion: {})
        }
    }
    
    func errorType(firAuthError error: Error) -> ErrorType {
        
        var errorType: ErrorType!
        
        let debugStr = String(describing: error)
        
        if let errCode = AuthErrorCode(rawValue: error._code) {
            
            errorType = ErrorType.loginDefault(debugStr)
            
            switch errCode {
            case .invalidEmail:
                errorType = ErrorType.regInvalidEmail(debugStr)
            case .emailAlreadyInUse:
                errorType = ErrorType.regExistingUser(debugStr)
            case .networkError:
                errorType = ErrorType.serverError(debugStr)
            case .weakPassword:
                errorType = ErrorType.regWeakPassword(debugStr)
            case .wrongPassword:
                errorType = ErrorType.regWrongPassword(debugStr)
            default:
                errorType = ErrorType.loginDefault(debugStr)
            }
        }
        return errorType
    }
    
    
    @IBAction func resetPwButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "presentResetPwVc", sender: nil)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentResetPwVc" {

        }
    }
    
    @IBAction func userNameLoginPressed(_ sender: Any) {
        
        self.emailTextfield.resignFirstResponder()
        self.passwordTextfield.resignFirstResponder()
        
        Auth.auth().signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { [weak self] (user, error) in
            
            guard let strongSelf = self else { return }
            
            if error == nil {
                strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                
            } else {
                let errorType = ErrorType.loginError(String(describing: error))
                strongSelf.handleError(errorType: errorType)
            }
        }
    }
    
    @IBAction func registerPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Register",
                                      message: "Enter a valid email address and a password of at least 6 characters in length",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Go",
                                       style: .default) { action in
                                        
                                        let emailField = alert.textFields![0]
                                        let passwordField = alert.textFields![1]
                                        
                                        if let currentUser = Auth.auth().currentUser {
                                            
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        alert.addTextField { textEmail in
            textEmail.keyboardType = UIKeyboardType.emailAddress
            textEmail.borderStyle = UITextBorderStyle.bezel
            textEmail.placeholder = "Email"
            textEmail.tintColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.DEFAULT_BLUE_COLOR))
        }
        
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.borderStyle = UITextBorderStyle.bezel
            textPassword.clearsOnBeginEditing = true
            textPassword.placeholder = "Password"
            textPassword.tintColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.DEFAULT_BLUE_COLOR))
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func registerAnonymous(currentUser: User, email: String, password: String) {
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        currentUser.link(with: credential) { [weak self] (user, error) in
            
            guard let strongSelf = self else { return }
            
            if error == nil {
                Logger.print("Anonymous user: \(currentUser.uid) successfully linked to new registered user: \(String(describing: user?.email)), \(String(describing: user?.uid))")
                strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                
            } else {
                let errorType = strongSelf.errorType(firAuthError: error!)
                strongSelf.handleError(errorType: errorType)
            }
        }
    }
    
    func registerNewUser(email: String, password: String) {
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] user, error in
            
            guard let strongSelf = self else { return }
            
            if error == nil {
                strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if error == nil {
                        Logger.print("\(String(describing: user?.email)), \(String(describing: user?.uid)) successfully registered first time in app")
                        strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.email as String))
                    } else {
                        let errorType = strongSelf.errorType(firAuthError: error!)
                        strongSelf.handleError(errorType: errorType)
                    }
                }
            } else {
                let errorType = strongSelf.errorType(firAuthError: error!)
                strongSelf.handleError(errorType: errorType)
            }
        }
    }
    
    @IBAction func maybeLaterPressed(_ sender: Any) {
        
        let regType = logInDelegate?.getRegistrationType()
        
        if regType == RegistrationType.firstTimeInApp {
            
            Auth.auth().signInAnonymously() { [weak self] (user, error) in
                
                guard let strongSelf = self else { return }
                
                if error == nil {
                    Logger.print("A new user: \(String(describing: user?.email)), \(String(describing: user?.uid)) was successfully logged in anonymously")
                    strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.anonymousUser)
                    strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.anonymousLogin as String))
                } else {
                    let errorType = ErrorType.anonymousLoginError(String(describing: error))
                    strongSelf.handleError(errorType: errorType)
                }
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func fbLoginButtonPressed(_ sender: Any) {
        
        fbLoginManager!.logIn(withReadPermissions: ["email"], from: self) { [weak self] (result, error) in
            
            guard let strongSelf = self else { return }
            
            if (error == nil){
                
                if let current = FBSDKAccessToken.current() {
                    
                    Logger.print("Facebook user is logged in")
                    Logger.print("Access Token")
                    Logger.print("String      : \(current.tokenString)")
                    Logger.print("User ID     : \(current.userID)")
                    Logger.print("App ID      : \(current.appID)")
                    Logger.print("Refresh Date: \(current.refreshDate)")
                }
                
                let fbLoginResult : FBSDKLoginManagerLoginResult = result!
                
                if fbLoginResult.grantedPermissions != nil {
                    
                    if(fbLoginResult.grantedPermissions.contains("email")) {
                        
                        strongSelf.getFBUserData()
                        
                        let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                        
                        if let currentUser = Auth.auth().currentUser {
                            
                            if currentUser.isAnonymous {
                                
                                strongSelf.registerAnonymousUserToFacebook(currentUser: currentUser, credential: credential)
                                
                            } else {
                                
                                strongSelf.registerNewUserToFacebook(credential: credential)
                            }
                            
                        } else {
                            
                            strongSelf.registerNewUserToFacebook(credential: credential)
                        }
                    }
                }
            }
        }
    }
    
    func registerAnonymousUserToFacebook(currentUser: User, credential: AuthCredential) {
        
        currentUser.link(with: credential) { [weak self] (user, error) in
            
            guard let strongSelf = self else { return }
            
            if error == nil {
                
                // TODO - This path needs tested; need new facebook test account
                Logger.print("An anonymous user: \(String(describing: currentUser.email)), \(currentUser.uid) was successfully registered with facebook")
                strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                
            } else {

                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    let errorType = strongSelf.errorType(firAuthError: error!)
                    strongSelf.handleError(errorType: errorType)
                    
                    
                    switch errCode {
                        
                    case .credentialAlreadyInUse:
                        // User logged in with a previously used facebook crendential. The anonymouse user credential was ignored, and user was logged in
                        strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                        strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))

                    default:
                        let errorType = strongSelf.errorType(firAuthError: error!)
                        strongSelf.handleError(errorType: errorType)
                    }    
                }
            }
        }
    }
    
    func registerNewUserToFacebook(credential: AuthCredential) {
        
        Auth.auth().signIn(with: credential) { [weak self] (user, error) in
            
            guard let strongSelf = self else { return }
            
            if error == nil {
                
                Logger.print("A new user: \(String(describing: user?.email)), \(String(describing: user?.uid)) was successfully logged in via facebook")
                strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                
            } else {
                
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    let errorType = strongSelf.errorType(firAuthError: error!)
                    strongSelf.handleError(errorType: errorType)
                    
                    switch errCode {
                        
                    case .credentialAlreadyInUse:
                        // User logged in with a previously used facebook crendential. The anonymouse user credential was ignored, and user was logged in
                        strongSelf.logInDelegate?.setRegistrationType(with: RegistrationType.registered)
                        strongSelf.logInDelegate?.handleUserLoggedIn(via: (LogInType.facebook as String))
                        
                    default:
                        let errorType = strongSelf.errorType(firAuthError: error!)
                        strongSelf.handleError(errorType: errorType)
                    }
                }
            }
        }
    }
    
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { [weak self] (connection, result, error) -> Void in
                
                guard let strongSelf = self else { return }
                
                if (error == nil) {
                    strongSelf.dict = result as! [String : AnyObject]
                    Logger.print("RESULT: \(result!)")
                    Logger.print("DICT: \(strongSelf.dict)")
                    //imageView.downloadedFrom(link: "http://www.apple.com/euro/ios/ios8/a/generic/images/og.png")
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            
            guard let strongSelf = self else { return }
            
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                strongSelf.image = image
            }
            }.resume()
    }
    
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
