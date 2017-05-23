//
//  ResetPwViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 5/9/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import Firebase

class ResetPwViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameTextfield.delegate = self
        usernameTextfield.keyboardType = UIKeyboardType.emailAddress
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        sendResetPwButtonClicked(self)
        return false
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    @IBAction func sendResetPwButtonClicked(_ sender: Any) {
        let username = self.usernameTextfield.text!
        Auth.auth().sendPasswordReset(withEmail: username) { error in
            if error == nil {
                self.presentAlert(email: username)
            } else {
                let errorType = ErrorType.loginError(String(describing: error))
                NSLog("errorType: \(errorType)")
            }
        }
    }
    
    func presentAlert(email: String) {
        
        self.usernameTextfield.resignFirstResponder()
        
        let message = "A password reset message has been sent to \(email)"
            
        let alert = UIAlertController(title: "Password Reset",
                                      message: message,
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok",
                                       style: .default) { action in
            
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
