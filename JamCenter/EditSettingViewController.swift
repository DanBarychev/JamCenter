//
//  EditSettingViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 6/13/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class EditSettingViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    
    var settingName: String?
    var settingVal: String?
    
    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var settingTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingTextField.delegate = self
        
        navigationItem.title = "Edit " + (settingName ?? "")
        settingLabel.text = settingVal
        saveButton.isEnabled = false
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        settingLabel.text = settingTextField.text!
        saveButton.isEnabled = true
    }

    // MARK: Action
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        saveSetting()
        saveButton.isEnabled = false
    }
    
    // Firebase Upload
    
    func saveSetting() {
        guard let settingUploadVal = settingLabel.text, let uid = Auth.auth().currentUser?.uid,
                let settingUploadName = settingName else {
            return
        }

        let ref = Database.database().reference()
        let usersRef = ref.child("users").child(uid)
        let values = ["\(settingUploadName.lowercased())": settingUploadVal]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print(error)
                return
            }
            else {
                // Setting successfully saved
            }
        })
    }
}
