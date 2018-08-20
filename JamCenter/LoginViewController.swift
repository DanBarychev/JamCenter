//
//  LoginViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Background photo by Edward Castro from Pexels.com

import UIKit
import Firebase
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    typealias userExistsClosure = (Bool?) -> Void
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var facebookLoginButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var noAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        facebookLoginButton.layer.cornerRadius = 20
        loginButton.layer.cornerRadius = 20
        noAccountButton.layer.cornerRadius = 20
        
        facebookLoginButton.layer.borderWidth = 2.0
        loginButton.layer.borderWidth = 2.0
        noAccountButton.layer.borderWidth = 2.0
        
        facebookLoginButton.layer.borderColor = UIColor.white.withAlphaComponent(0.0).cgColor
        loginButton.layer.borderColor = UIColor.white.cgColor
        noAccountButton.layer.borderColor = UIColor.white.cgColor
        
        facebookLoginButton.layer.backgroundColor = self.view.tintColor.withAlphaComponent(0.75).cgColor
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
    }
    
    // MARK: Facebook Login
    
    func handleFacebookLogin() {
        let spinner = UIViewController.showSpinner(onView: self.view)
        
        guard let authenticationToken = AccessToken.current?.authenticationToken else { return }
        let credential = FacebookAuthProvider.credential(withAccessToken: authenticationToken)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            // Facebook login successfully authenticated with Firebase
            
            guard let uid = Auth.auth().currentUser?.uid else {
                return
            }
            
            //If the user doesn't exist yet, save him/her
            self.userExists(uid: uid) { (userExists) in
                if let userExists = userExists {
                    if !userExists {
                        self.handleFacebookUser(uid: uid, spinner: spinner)
                    } else {
                        UIViewController.removeSpinner(spinner: spinner)
                        self.performSegue(withIdentifier: "Login", sender: nil)
                    }
                }
            }
        }
    }
    
    func handleFacebookUser(uid: String, spinner: UIView) {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email, picture.type(large)"]).start { (connection, result, error) in
            if let error = error {
                print(error)
                return
            }
            
            if let resultDict = result as? [String: AnyObject] {
                print(resultDict)
                
                guard let name = resultDict["name"] as? String, let email = resultDict["email"] as? String,
                    let profilePictureDict = resultDict["picture"] as? [String: AnyObject],
                    let profilePictureDataDict = profilePictureDict["data"] as? [String: AnyObject],
                    let profilePictureURL = profilePictureDataDict["url"] as? String
                else {
                    return
                }
                
                self.saveFacebookUser(uid: uid, name: name, email: email, profilePictureURL: profilePictureURL, spinner: spinner)
            }
        }
    }
    
    func saveFacebookUser(uid: String, name: String, email: String, profilePictureURL: String, spinner: UIView) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.photoURL = NSURL(string: profilePictureURL)! as URL
        changeRequest?.commitChanges { (error) in
            if let error = error {
                print(error)
            } else {
                // Change request successful
            }
        }
        
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        let values = ["name": name, "email": email, "profileImageURL": profilePictureURL,
                      "numSessions": "0"]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print(error)
                return
            }
            else {
                // User successfully saved
                UIViewController.removeSpinner(spinner: spinner)
                
                self.performSegue(withIdentifier: "GoToCountrySelectorFromLogin", sender: nil)
            }
        })
    }
    
    func userExists(uid: String, completionHandler: @escaping userExistsClosure) {
        let ref = Database.database().reference()
        let allUsersRef = ref.child("users")
        
        allUsersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(uid){
                // User exists
                completionHandler(true)
            } else{
                // User doesn't exist
                completionHandler(false)
            }
        })
    }
    
    // MARK: Firebase Login
    
    func handleStandardLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text
            else {
                //invalid entry
                return
        }
        
        let spinner = UIViewController.showSpinner(onView: self.view)
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error = error {
                print(error)
                
                UIViewController.removeSpinner(spinner: spinner)
                
                let loginAlert = UIAlertController(title: "Invalid Login", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                loginAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(loginAlert, animated: true, completion: nil)
                
                return
            }
            else {
                // User successfully logged in
                UIViewController.removeSpinner(spinner: spinner)
                
                self.performSegue(withIdentifier: "Login", sender: nil)
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func login(_ sender: UIButton) {
        handleStandardLogin()
    }
    
    @IBAction func facebookLogin(_ sender: UIButton) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: self) { (result) in
            switch result {
            case .success(grantedPermissions: _, declinedPermissions: _, token: _):
                self.handleFacebookLogin()
            case .failed(let error):
                print(error)
            case .cancelled:
                print("Facebook login cancelled")
            }
        }
    }
    
    
    // MARK: Navigation
    
    @IBAction func unwindToLoginScreen(sender: UIStoryboardSegue) {
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCountrySelectorFromLogin" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SelectCountryTableViewController
            
            newViewController.loginType = "Facebook"
        }
    }
}
