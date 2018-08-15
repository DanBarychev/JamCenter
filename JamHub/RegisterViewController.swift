//
//  RegisterViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Back Icon from https://icons8.com/icon/39815/Go-Back
//  Background photo by Tim Savage from Pexels.com

import UIKit
import Firebase

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        registerButton.layer.cornerRadius = 20
        registerButton.layer.borderWidth = 2
        registerButton.layer.borderColor = UIColor.white.cgColor
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
    
    func handleRegister() {
        guard let name = nameTextField.text, let email = emailTextField.text, let password = passwordTextField.text
            else {
                //invalid entry
                return
        }
        
        let spinner = UIViewController.showSpinner(onView: self.view)
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if error != nil {
                print(error!)
                
                UIViewController.removeSpinner(spinner: spinner)
                
                let registrationAlert = UIAlertController(title: "Invalid Registration", message: "There Was An Error With The Submission", preferredStyle: UIAlertControllerStyle.alert)
                registrationAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(registrationAlert, animated: true, completion: nil)
            }
            
            guard let uid = authResult?.user.uid else {
                return
            }
            
            //Generic Profile Photo Upload
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            if let profileImage = UIImage(named: "GenericProfilePicture"), let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
                storageRef.putData(uploadData, metadata: nil, completion: {(metadata, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    else {
                        storageRef.downloadURL { (url, error) in
                            guard let profileImageURL = url?.absoluteString else {
                                return
                            }
                            
                            self.finishRegistrationWithUserData(uid: uid, name: name, email: email,
                                                                profileImageLink: profileImageURL, spinner: spinner)
                        }
                    }
                })
            }
        }
    }
    
    func finishRegistrationWithUserData(uid: String, name: String, email: String, profileImageLink: String, spinner: UIView) {
        // Set the user display name and photoURL
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.photoURL = NSURL(string: profileImageLink)! as URL
        changeRequest?.commitChanges { (error) in
            if let error = error {
                print(error)
            } else {
                print("Change request successful")
            }
        }
        
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        let values = ["name": name, "email": email, "profileImageURL": profileImageLink, "numSessions": "0"]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print(error)
                UIViewController.removeSpinner(spinner: spinner)
                
                return
            }
            else {
                print("User Successfully Saved Into Database")
                UIViewController.removeSpinner(spinner: spinner)
                
                self.performSegue(withIdentifier: "SetupProfilePicture", sender: nil)
            }
        })
    }
    

    // MARK: Actions
    @IBAction func register(_ sender: UIButton) {
        handleRegister()
    }
}
