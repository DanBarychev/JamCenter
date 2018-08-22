//
//  ActiveCurrentSessionViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 7/8/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Video icon from https://icons8.com/icon/11402/Video-Call-Filled
// Audio icon from https://icons8.com/icon/9403/Music-Record-Filled
// Songs icon from https://icons8.com/icon/41815/Sheet-Music-Filled

import UIKit

class ActiveCurrentSessionViewController: UIViewController {
    
    // MARK: Properties
    var currentSession: Session?
    @IBOutlet weak var actionsCollectionView: UICollectionView!
    
    let actionsCellIds = ["AudioCell", "SongsCell"]
    let actionsCellSizes = Array(repeatElement(CGSize(width:165, height:140), count: 2))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionsCollectionView.delegate = self
        actionsCollectionView.dataSource = self
        
        if let currentJamSession = currentSession {
            navigationItem.title = currentJamSession.name
        }
    }
    
    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToAudio" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! AudioViewController
            
            newViewController.currentSession = currentSession
        } else if segue.identifier == "GoToSongs" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SongsTableViewController
            
            newViewController.mySession = currentSession
        }
    }
    
    @IBAction func unwindToActiveSession(sender: UIStoryboardSegue) {
    }
}

// MARK: Collection View

extension ActiveCurrentSessionViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionsCellIds.count
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return actionsCollectionView.dequeueReusableCell(withReuseIdentifier: actionsCellIds[indexPath.item], for: indexPath)
    }
}

extension ActiveCurrentSessionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return actionsCellSizes[indexPath.item]
    }
    
    // Center the cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 165.0
        
        let numberOfCells = 2 as CGFloat
        let edgeInsets = (self.actionsCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsetsMake(15, edgeInsets, 0, edgeInsets)
        } else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
}
