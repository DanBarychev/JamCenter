//
//  OtherMusicianProfileViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/8/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class OtherMusicianProfileViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var propertiesCollectionView: UICollectionView!
    
    var origin: String?
    var selectedMusician: Musician?
    var instruments = String()
    var genres = String()
    var location = String()
    var numSessions = String()
    
    let propertyTitles = ["Instruments","Genres","Location","Sessions"]
    let propertyCellSizes = Array(repeatElement(CGSize(width:165, height:138), count: 4))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.clipsToBounds = true
        
        propertiesCollectionView.delegate = self
        propertiesCollectionView.dataSource = self
        
        if let musician = selectedMusician {
            nameLabel.text = musician.name
            if let profileImageURL = musician.profileImageURL {
                profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
            }
            
            guard let musicianInstruments = musician.instruments, let musicianGenres = musician.genres, let musicianCity = musician.city, let musicianCountry = musician.country else {
                return
            }
            
            instruments = musicianInstruments
            genres = musicianGenres
            location = "\(musicianCity),\n\(musicianCountry)"
            numSessions = String(musician.numSessions ?? 0)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2.0
    }
    
    // MARK: Actions
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        guard let origin = origin else {
            return
        }
        
        if origin == "NewSession" {
            performSegue(withIdentifier: "UnwindToNewSessionFromOtherMusician", sender: nil)
        } else {
            performSegue(withIdentifier: "UnwindToCurrentJamFromOtherMusician", sender: nil)
        }
    }
}

// MARK: Collection View

extension OtherMusicianProfileViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return propertyTitles.count
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = propertiesCollectionView.dequeueReusableCell( withReuseIdentifier: "OtherProfileCell", for: indexPath) as! OtherProfileCollectionViewCell
        
        let propertyTitle = propertyTitles[indexPath.row]
        cell.nameLabel.text = propertyTitle
        
        if propertyTitle == "Instruments" {
            cell.valueLabel.text = instruments
        } else if propertyTitle == "Genres" {
            cell.valueLabel.text = genres
        } else if propertyTitle == "Location" {
            cell.valueLabel.text = location
        } else if propertyTitle == "Sessions" {
            cell.valueLabel.text = numSessions
        }
        
        return cell
    }
}

extension OtherMusicianProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return propertyCellSizes[indexPath.item]
    }
    
    // Center the cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 165.0
        
        let numberOfCells = 4 as CGFloat
        let edgeInsets = (self.propertiesCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsetsMake(15, edgeInsets, 0, edgeInsets)
        } else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
}
