//
//  ProfilePictureViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/1/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class ProfilePictureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2
        self.imageView.clipsToBounds = true

        imagePicker.delegate = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleToFill
            imageView.image = pickedImage
        }
        
        //PROFILE IMAGE UPLOAD
        let imageName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).png")
        
        if let profileImage = self.imageView.image, let uploadData = UIImageJPEGRepresentation(profileImage, 0.1) {
            storageRef.putData(uploadData, metadata: nil, completion:
                {(metadata, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    else {
                        storageRef.downloadURL { (url, error) in
                            guard let profileImageURL = url?.absoluteString else {
                                return
                            }
                            self.userDataUpdateWithProfileImage(profileImageLink: profileImageURL)
                        }
                    }
            })
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func imageViewTapped(_ sender: Any) {
        print("Image Tapped!")
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: Firebase Data Upload
    
    private func userDataUpdateWithProfileImage(profileImageLink: String) {
        // Update the user photoURL
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = NSURL(string: profileImageLink)! as URL
        changeRequest?.commitChanges { (error) in
            if error != nil {
                print(error!)
            } else {
                print("Change request successful")
            }
        }
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let usersRef = ref.child("users").child(uid!)
        let values = ["profileImageURL": profileImageLink]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            else {
                print("User Data Successfully Updated")
            }
        })
    }
    
    // MARK: Navigation
    
    @IBAction func unwindToProfilePictureScreen(sender: UIStoryboardSegue) {
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCountrySelectorFromProfilePicture" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SelectCountryTableViewController
            
            newViewController.loginType = "Standard"
        }
    }
}
