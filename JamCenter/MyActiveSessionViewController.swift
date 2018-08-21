//
//  MyActiveSessionViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/11/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Key Icon from https://icons8.com/icon/555/Key
//  Circle Icon from https://icons8.com/icon/24608/Unchecked-Circle
//  Settings Icon from https://icons8.com/icon/364/Settings

import UIKit
import Firebase
import FacebookShare

class MyActiveSessionViewController: UIViewController {
    
    // MARK: Properties
    
    var mySession: Session?
    var sessionID = String()
    var sessionHostUID = String()
    var sessionCode = String()
    var sessionLocation = String()
    var sessionMusicians = [Musician]()
    
    let actionsCellIds = ["ShareCell", "RecordAudioCell", "AddToSonglistCell", "GetCodeCell"]
    let actionsCellSizes = Array(repeatElement(CGSize(width:165, height:140), count: 4))
    
    @IBOutlet weak var actionsCollectionView: UICollectionView!
    @IBOutlet weak var endSessionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionsCollectionView.delegate = self
        actionsCollectionView.dataSource = self

        if let session = mySession {
            navigationItem.title = session.name
            sessionID = session.ID ?? ""
            sessionHostUID = session.hostUID ?? ""
            sessionCode = session.code ?? "Code Unavailable"
            sessionLocation = session.location ?? "Unknown"
            sessionMusicians = session.musicians ?? []
            if !(session.isActive ?? false) {
                endSessionButton.isHidden = true
            }
            
            endSessionButton.layer.cornerRadius = 25
            endSessionButton.layer.borderWidth = 2
            endSessionButton.layer.borderColor = UIColor.white.cgColor
        }
    }

    // MARK: Firebase Functions
    
    func endSession() {
        let values = ["isActive": "false"]
        
        let ref = Database.database().reference()
        let allSessionsKey = ref.child("all sessions").child(sessionID)
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print (error)
                return
            }
            else {
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func shareTapped(_ sender: UIButton) {
        let content = LinkShareContent(url: URL(string: "http://www.jamcenterapp.com")!)
        do {
            try ShareDialog.show(from: self, content: content)
        } catch {
        }
    }
    
    @IBAction func getCodeTapped(_ sender: UIButton) {
        let codeAlert = UIAlertController(title: sessionCode, message: "", preferredStyle: UIAlertControllerStyle.alert)
        codeAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(codeAlert, animated: true, completion: nil)
    }
    
    @IBAction func endSessionTapped(_ sender: UIButton) {
        endSession()
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToMyAudio" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MyAudioViewController
            
            newViewController.mySession = mySession
        } else if segue.identifier == "GoToMySongs" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! MySongsTableViewController
            
            newViewController.mySession = mySession
        }
    }
    
    @IBAction func unwindToMyActiveSession(sender: UIStoryboardSegue) {
    }
}

// MARK: Collection View

extension MyActiveSessionViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionsCellIds.count
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return actionsCollectionView.dequeueReusableCell(withReuseIdentifier: actionsCellIds[indexPath.item], for: indexPath)
    }
}

extension MyActiveSessionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return actionsCellSizes[indexPath.item]
    }
    
    // Center the cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 165.0
        
        let numberOfCells = 4 as CGFloat
        let edgeInsets = (self.actionsCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsetsMake(15, edgeInsets, 0, edgeInsets)
        } else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
}
