//
//  LoginViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate {
    
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
        
        let facebookLoginButton = FBSDKLoginButton()
        facebookLoginButton.delegate = self
        view.addSubview(facebookLoginButton)
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        facebookLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        facebookLoginButton.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor, constant: -70).isActive = true
        facebookLoginButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -130).isActive = true
        facebookLoginButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        facebookLoginButton.readPermissions = ["email","public_profile"]
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
    
    // Facebook Login
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        handleFacebookLogin()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("User logged out of Facebook account")
    }
    
    // Firebase Login
    
    func handleStandardLogin() {
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
    
    func handleFacebookLogin() {
        guard let authenticationToken = AccessToken.current?.authenticationToken else { return }
        let credential = FacebookAuthProvider.credential(withAccessToken: authenticationToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            print("Succesfully authenticated with Firebase.")
            self.performSegue(withIdentifier: "Login", sender: nil)
            //Handle saving user into Firebase
        }
    }
    
    // MARK: Navigation
    @IBAction func unwindToLoginScreen(sender: UIStoryboardSegue) {
    }

    
    // MARK: Actions
    @IBAction func login(_ sender: UIButton) {
        handleStandardLogin()
    }
    

}
