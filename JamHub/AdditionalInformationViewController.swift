//
//  AdditionalInformationViewController.swift
//  JamHub
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
    
    //Genre Icons
    @IBOutlet weak var rockIcon: UIImageView!
    @IBOutlet weak var jazzIcon: UIImageView!
    @IBOutlet weak var rapIcon: UIImageView!
    @IBOutlet weak var popIcon: UIImageView!
    @IBOutlet weak var countryIcon: UIImageView!
    @IBOutlet weak var classicalIcon: UIImageView!
    
    //Instrument Icons
    @IBOutlet weak var guitarIcon: UIImageView!
    @IBOutlet weak var bassIcon: UIImageView!
    @IBOutlet weak var pianoIcon: UIImageView!
    @IBOutlet weak var drumsIcon: UIImageView!
    @IBOutlet weak var microphoneIcon: UIImageView!
    @IBOutlet weak var violinIcon: UIImageView!
    @IBOutlet weak var celloIcon: UIImageView!
    @IBOutlet weak var clarinetIcon: UIImageView!
    @IBOutlet weak var saxophoneIcon: UIImageView!
    @IBOutlet weak var trumpetIcon: UIImageView!
    @IBOutlet weak var tromboneIcon: UIImageView!
    @IBOutlet weak var tubaIcon: UIImageView!
    @IBOutlet weak var frenchHornIcon: UIImageView!
    @IBOutlet weak var fluteIcon: UIImageView!
    @IBOutlet weak var harmonicaIcon: UIImageView!
    @IBOutlet weak var noteIcon: UIImageView!
    
    var genres = [String]()
    var instruments = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Upload to Firebase
    
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
            
            if error != nil {
                print(error!)
                return
            }
            else {
                print("User Data Successfully Updated")
                
                self.performSegue(withIdentifier: "Register", sender: nil)
                
            }
        })
    }
    
    // MARK: Actions
    
    // Genre Icons
    @IBAction func rockIconSelected(_ sender: UITapGestureRecognizer) {
        if (rockIcon.isHighlighted) {
            rockIcon.isHighlighted = false
            
            if let index = genres.index(of: "Rock") {
                genres.remove(at: index)
            }
        } else {
            rockIcon.isHighlighted = true
            genres.append("Rock")
        }
    }
    
    @IBAction func jazzIconSelected(_ sender: UITapGestureRecognizer) {
        if (jazzIcon.isHighlighted) {
            jazzIcon.isHighlighted = false
            
            if let index = genres.index(of: "Jazz/Blues") {
                genres.remove(at: index)
            }
        } else {
            jazzIcon.isHighlighted = true
            genres.append("Jazz/Blues")
        }
    }
    
    @IBAction func rapIconSelected(_ sender: UITapGestureRecognizer) {
        if (rapIcon.isHighlighted) {
            rapIcon.isHighlighted = false
            
            if let index = genres.index(of: "Rap/Hip-Hop") {
                genres.remove(at: index)
            }
        } else {
            rapIcon.isHighlighted = true
            genres.append("Rap/Hip-Hop")
        }
    }
    
    @IBAction func popIconSelected(_ sender: UITapGestureRecognizer) {
        if (popIcon.isHighlighted) {
            popIcon.isHighlighted = false
            
            if let index = genres.index(of: "Pop") {
                genres.remove(at: index)
            }
        } else {
            popIcon.isHighlighted = true
            genres.append("Pop")
        }
    }
    
    @IBAction func countryIconSelected(_ sender: UITapGestureRecognizer) {
        if (countryIcon.isHighlighted) {
            countryIcon.isHighlighted = false
            
            if let index = genres.index(of: "Country") {
                genres.remove(at: index)
            }
        } else {
            countryIcon.isHighlighted = true
            genres.append("Country")
        }
    }
    
    @IBAction func classicalIconSelected(_ sender: UITapGestureRecognizer) {
        if (classicalIcon.isHighlighted) {
            classicalIcon.isHighlighted = false
            
            if let index = genres.index(of: "Classical") {
                genres.remove(at: index)
            }
        } else {
            classicalIcon.isHighlighted = true
            genres.append("Classical")
        }
    }
    
    
    // Instrument Icons
    @IBAction func guitarIconSelected(_ sender: UITapGestureRecognizer) {
        if (guitarIcon.isHighlighted) {
            guitarIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Guitar") {
                instruments.remove(at: index)
            }
        } else {
            guitarIcon.isHighlighted = true
            instruments.append("Guitar")
        }
    }
    
    @IBAction func bassIconSelected(_ sender: UITapGestureRecognizer) {
        if (bassIcon.isHighlighted) {
            bassIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Bass") {
                instruments.remove(at: index)
            }
        } else {
            bassIcon.isHighlighted = true
            instruments.append("Bass")
        }
    }
    
    @IBAction func pianoIconSelected(_ sender: UITapGestureRecognizer) {
        if (pianoIcon.isHighlighted) {
            pianoIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Piano") {
                instruments.remove(at: index)
            }
        } else {
            pianoIcon.isHighlighted = true
            instruments.append("Piano")
        }
    }
    
    @IBAction func drumsIconSelected(_ sender: UITapGestureRecognizer) {
        if (drumsIcon.isHighlighted) {
            drumsIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Drums") {
                instruments.remove(at: index)
            }
        } else {
            drumsIcon.isHighlighted = true
            instruments.append("Drums")
        }
    }
    
    @IBAction func microphoneIconSelected(_ sender: UITapGestureRecognizer) {
        if (microphoneIcon.isHighlighted) {
            microphoneIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Vocals") {
                instruments.remove(at: index)
            }
        } else {
            microphoneIcon.isHighlighted = true
            instruments.append("Vocals")
        }
    }
    
    @IBAction func violinIconSelected(_ sender: UITapGestureRecognizer) {
        if (violinIcon.isHighlighted) {
            violinIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Violin") {
                instruments.remove(at: index)
            }
        } else {
            violinIcon.isHighlighted = true
            instruments.append("Violin")
        }
    }
    
    @IBAction func celloIconSelected(_ sender: UITapGestureRecognizer) {
        if (celloIcon.isHighlighted) {
            celloIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Cello") {
                instruments.remove(at: index)
            }
        } else {
            celloIcon.isHighlighted = true
            instruments.append("Cello")
        }
    }
    
    @IBAction func clarinetIconSelected(_ sender: UITapGestureRecognizer) {
        if (clarinetIcon.isHighlighted) {
            clarinetIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Clarinet") {
                instruments.remove(at: index)
            }
        } else {
            clarinetIcon.isHighlighted = true
            instruments.append("Clarinet")
        }
    }
    
    @IBAction func saxophoneIconSelected(_ sender: UITapGestureRecognizer) {
        if (saxophoneIcon.isHighlighted) {
            saxophoneIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Saxophone") {
                instruments.remove(at: index)
            }
        } else {
            saxophoneIcon.isHighlighted = true
            instruments.append("Saxophone")
        }
    }
    
    @IBAction func trumpetIconSelected(_ sender: Any) {
        if (trumpetIcon.isHighlighted) {
            trumpetIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Trumpet") {
                instruments.remove(at: index)
            }
        } else {
            trumpetIcon.isHighlighted = true
            instruments.append("Trumpet")
        }
    }
    
    @IBAction func tromboneIconSelected(_ sender: UITapGestureRecognizer) {
        if (tromboneIcon.isHighlighted) {
            tromboneIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Trombone") {
                instruments.remove(at: index)
            }
        } else {
            tromboneIcon.isHighlighted = true
            instruments.append("Trombone")
        }
    }
    
    @IBAction func tubaIconSelected(_ sender: UITapGestureRecognizer) {
        if (tubaIcon.isHighlighted) {
            tubaIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Tuba") {
                instruments.remove(at: index)
            }
        } else {
            tubaIcon.isHighlighted = true
            instruments.append("Tuba")
        }
    }
    
    @IBAction func frenchHornIconSelected(_ sender: UITapGestureRecognizer) {
        if (frenchHornIcon.isHighlighted) {
            frenchHornIcon.isHighlighted = false
            
            if let index = instruments.index(of: "French Horn") {
                instruments.remove(at: index)
            }
        } else {
            frenchHornIcon.isHighlighted = true
            instruments.append("French Horn")
        }
    }
    
    @IBAction func fluteIconSelected(_ sender: UITapGestureRecognizer) {
        if (fluteIcon.isHighlighted) {
            fluteIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Flute") {
                instruments.remove(at: index)
            }
        } else {
            fluteIcon.isHighlighted = true
            instruments.append("Flute")
        }
    }
    
    @IBAction func harmonicaIconSelected(_ sender: UITapGestureRecognizer) {
        if (harmonicaIcon.isHighlighted) {
            harmonicaIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Harmonica") {
                instruments.remove(at: index)
            }
        } else {
            harmonicaIcon.isHighlighted = true
            instruments.append("Harmonica")
        }
    }
    
    @IBAction func noteIconSelected(_ sender: UITapGestureRecognizer) {
        if (noteIcon.isHighlighted) {
            noteIcon.isHighlighted = false
            
            if let index = instruments.index(of: "Other") {
                instruments.remove(at: index)
            }
        } else {
            noteIcon.isHighlighted = true
            instruments.append("Other")
        }
    }
    
    @IBAction func finishButtonSelected(_ sender: UIBarButtonItem) {
        uploadSelections()
    }
    
}
