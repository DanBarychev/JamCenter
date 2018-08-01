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
    
    typealias userExistsClosure = (Bool?) -> Void
    
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
            
            //Handle saving user into Firebase
            self.handleFacebookUser()
            
            self.performSegue(withIdentifier: "Login", sender: nil)
        }
    }
    
    func handleFacebookUser() {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email, picture.type(large)"]).start { (connection, result, error) in
            if let error = error {
                print(error)
                return
            }
            // In the case of a successful Graph Request we want to print out the result
            if let resultDict = result as? [String: AnyObject] {
                print(resultDict)
                
                guard let uid = Auth.auth().currentUser?.uid,
                    let name = resultDict["name"] as? String, let email = resultDict["email"] as? String,
                    let profilePictureDict = resultDict["picture"] as? [String: AnyObject],
                    let profilePictureDataDict = profilePictureDict["data"] as? [String: AnyObject],
                    let profilePictureURL = profilePictureDataDict["url"] as? String
                else {
                    return
                }
                
                self.saveFacebookUser(uid: uid, name: name, email: email, profilePictureURL: profilePictureURL)
            }
        }
    }
    
    func saveFacebookUser(uid: String, name: String, email: String, profilePictureURL: String) {
        self.userExists(uid: uid) { (userExists) in
            if let userExists = userExists {
                if !userExists {
                    print("USER DOESNT EXIST")
                    print(uid)
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = name
                    changeRequest?.photoURL = NSURL(string: profilePictureURL)! as URL
                    changeRequest?.commitChanges { (error) in
                        if error != nil {
                            print(error!)
                        } else {
                            print("Change request successful")
                        }
                    }
                    
                    let ref = Database.database().reference()
                    let usersRef = ref.child("users").child(uid)
                    let values = ["name": name, "email": email, "profileImageURL": profilePictureURL]
                    usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        else {
                            print("User Successfully Saved Into Database")
                        }
                    })
                }
            }
        }
    }
    
    func userExists(uid: String, completionHandler: @escaping userExistsClosure) {
        let ref = Database.database().reference()
        let allUsersRef = ref.child("users")
        
        allUsersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(uid){
                print("User Exists")
                completionHandler(true)
            } else{
                print("User Doesn't Exist")
                completionHandler(false)
            }
        })
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
    
    // MARK: Navigation
    @IBAction func unwindToLoginScreen(sender: UIStoryboardSegue) {
    }

    
    // MARK: Actions
    @IBAction func login(_ sender: UIButton) {
        handleStandardLogin()
    }
    

}
