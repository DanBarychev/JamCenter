//
//  LoginViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButton.layer.cornerRadius = 20
        noAccountButton.layer.cornerRadius = 20
        
        loginButton.layer.borderWidth = 2.0
        noAccountButton.layer.borderWidth = 2.0
        
        loginButton.layer.borderColor = UIColor.white.cgColor
        noAccountButton.layer.borderColor = UIColor.white.cgColor
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text
            else {
                //invalid entry
                return
        }
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!)
                let loginAlert = UIAlertController(title: "Invalid Login", message: "Incorrect Email or Password", preferredStyle: UIAlertControllerStyle.alert)
                loginAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(loginAlert, animated: true, completion: nil)
                
                return
            }
            else {
                print("User Successfully Logged In")
                self.performSegue(withIdentifier: "Login", sender: nil)
            }
        })
        
    }
    
    // MARK: Navigation

    @IBAction func unwindToLoginScreen(sender: UIStoryboardSegue) {
    }

    // MARK: Actions
    
    @IBAction func login(_ sender: UIButton) {
        handleLogin()
    }
    


}
