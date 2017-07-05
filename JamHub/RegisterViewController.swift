//
//  RegisterViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase
import SwiftVideoBackground

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    @IBOutlet weak var backgroundVideo: BackgroundVideo!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundVideo.createBackgroundVideo(name: "ColtraneBackground", type: "mp4", alpha: 0.5)
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
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
        
        Auth.auth().createUser(withEmail: email, password: password, completion: { (user: User?, error) in
            if error != nil {
                print(error!)
                
                let registrationAlert = UIAlertController(title: "Invalid Registration", message: "There Was An Error With The Submission", preferredStyle: UIAlertControllerStyle.alert)
                registrationAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(registrationAlert, animated: true, completion: nil)
            }
            
            guard let uid = user?.uid else {
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
                        if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                            self.finishRegistrationWithUserData(uid: uid, name: name, email: email, profileImageLink: profileImageURL)
                        }
                    }
                })
            }
        })
    }
    
    func finishRegistrationWithUserData(uid: String, name: String, email: String, profileImageLink: String) {
        // Set the user display name and photoURL
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.photoURL = NSURL(string: profileImageLink)! as URL
        changeRequest?.commitChanges { (error) in
            if error != nil {
                print(error!)
            } else {
                print("Change request successful")
            }
        }
        
        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        let values = ["name": name, "email": email, "profileImageURL": profileImageLink]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            else {
                print("User Successfully Saved Into Database")
                
                self.performSegue(withIdentifier: "SetupProfilePicture", sender: nil)
            }
        })
    }
    

    // MARK: Actions
    
    @IBAction func register(_ sender: UIButton) {
        handleRegister()
    }
    

}
