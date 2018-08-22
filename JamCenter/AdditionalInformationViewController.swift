//
//  AdditionalInformationViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 7/1/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Rock Icon from https://icons8.com/icon/24862/progressive-rock
// Jazz Icon from https://icons8.com/icon/24854/Jazz
// Pop Icon from https://icons8.com/icon/11144/Electronic-Music
// Country Icon from https://icons8.com/icon/11142/country-music
// Rap/Hip-hop Icon from https://icons8.com/icon/1881/dj
// Classical Icon from https://icons8.com/icon/225/Music-Conductor
//
// Guitar Icon from https://icons8.com/icon/227/Guitar
// Bass Guitar Icon from https://icons8.com/icon/17785/Rock-Music
// Piano Icon from https://icons8.com/icon/11646/Classic-Music
// Drums Icon from https://icons8.com/icon/21711/Drum-Set
// Microphone Icon from https://icons8.com/icon/2830/Microphone-2
// Saxophone Icon from https://icons8.com/icon/1124/Saxophone
// Clarinet Icon from https://icons8.com/icon/9591/Clarinet
// Trumpet Icon from https://icons8.com/icon/1116/Trumpet
// Trombone Icon from https://icons8.com/icon/1498/Trombone
// Tuba Icon from https://icons8.com/icon/1114/Tuba
// Violin Icon from https://icons8.com/icon/229/Violin
// Cello Icon from https://icons8.com/icon/5325/Cello
// Harmonica Icon from https://icons8.com/icon/4413/Harmonica
// Flute Icon from https://icons8.com/icon/5326/Flute
// French Horn Icon from https://icons8.com/icon/1448/French-Horn
// Note Icon from https://icons8.com/icon/381/Music

import UIKit
import Firebase

class AdditionalInformationViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var genresCollectionView: UICollectionView!
    @IBOutlet weak var instrumentsCollectionView: UICollectionView!
    
    var genres = [String]()
    var instruments = [String]()
    
    let genresCellIds = ["Rock Cell","Jazz/Blues Cell","Rap/Hip-Hop Cell","Pop Cell", "Country Cell","Classical Cell"]
    let genresCellSizes = Array(repeatElement(CGSize(width:80, height:80), count: 6))
    
    let instrumentsCellIds = ["Guitar Cell","Bass Cell","Piano Cell","Drums Cell", "Vocals Cell","Violin Cell", "Viola Cell","Clarinet Cell", "Saxophone Cell","Trumpet Cell", "Trombone Cell","Tuba Cell", "French Horn Cell","Flute Cell", "Harmonica Cell","Other Cell"]
    let instrumentsCellSizes = Array(repeatElement(CGSize(width:75, height:75), count: 16))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        genresCollectionView.delegate = self
        genresCollectionView.dataSource = self
        instrumentsCollectionView.delegate = self
        instrumentsCollectionView.dataSource = self
    }
    
    // MARK: Firebase Upload
    
    func uploadSelections() {
        var genreSelections = ""
        var instrumentSelections = ""
        
        for genre in genres {
            if genreSelections == "" {
                genreSelections = genre
            } else {
                genreSelections += ", \(genre)"
            }
        }
        
        for instrument in instruments {
            if instrumentSelections == "" {
                instrumentSelections = instrument
            } else {
                instrumentSelections += ", \(instrument)"
            }
        }
        
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let usersRef = ref.child("users").child(uid!)
        let values = ["genres": genreSelections, "instruments": instrumentSelections]
        usersRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print(error)
                return
            }
            else {
                // User data successfully updated
                self.performSegue(withIdentifier: "Register", sender: nil)
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func finishButtonSelected(_ sender: UIBarButtonItem) {
        uploadSelections()
    }
}

// MARK: Collection View

extension AdditionalInformationViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == genresCollectionView {
            return genresCellIds.count
        } else {
            return instrumentsCellIds.count
        }
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == genresCollectionView {
            return genresCollectionView.dequeueReusableCell( withReuseIdentifier: genresCellIds[indexPath.item], for: indexPath)
        } else {
            return instrumentsCollectionView.dequeueReusableCell( withReuseIdentifier: instrumentsCellIds[indexPath.item], for: indexPath)
        }
    }
}

extension AdditionalInformationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == genresCollectionView {
            return genresCellSizes[indexPath.item]
        } else {
            return instrumentsCellSizes[indexPath.item]
        }
    }
}

extension AdditionalInformationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == genresCollectionView {
            let genreCellName = genresCellIds[indexPath.row]
            let genreName = genreCellName.replacingOccurrences(of: " Cell", with: "")
            genres = [genreName] // For now, we'll only allow one genre to be initially picked
        } else {
            let instrumentCellName = instrumentsCellIds[indexPath.row]
            let instrumentName = instrumentCellName.replacingOccurrences(of: " Cell", with: "")
            instruments = [instrumentName] // For now, we'll only allow one instrument to be initially picked
        }
    }
}
