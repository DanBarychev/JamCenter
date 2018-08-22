//
//  MyAudioViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/17/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Play icon from https://icons8.com/icon/25603/Circled-Play
// Microphone Icon from https://icons8.com/icon/12653/Microphone
// Pause Icon from https://icons8.com/icon/24890/Pause-Button
// Recording code snippets are based off of those on "Hacking with Swift"
// Timer adapted from https://medium.com/ios-os-x-development/build-an-stopwatch-with-swift-3-0-c7040818a10f

import UIKit
import AVFoundation
import Firebase

class MyAudioViewController: UIViewController, AVAudioRecorderDelegate {
    
    // MARK: Properties
    
    var mySession: Session?
    var sessionID = String()
    var sessionHostUID = String()
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var controlsCollectionView: UICollectionView!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var tapMicrophoneLabel: UILabel!
    @IBOutlet weak var recordingClockLabel: UILabel!
    @IBOutlet weak var uploadRecordingButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    var seconds = 0
    var timer = Timer()
    var resumeTapped = false
    
    let controlsCellIds = ["PlayCell", "PauseCell"]
    let controlsCellSizes = Array(repeatElement(CGSize(width:165, height:140), count: 2))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        controlsCollectionView.delegate = self
        controlsCollectionView.dataSource = self
        
        controlsCollectionView.isHidden = true
        recordingLabel.isHidden = true
        uploadRecordingButton.isHidden = true
        uploadRecordingButton.layer.cornerRadius = 25
        uploadRecordingButton.layer.borderWidth = 2
        uploadRecordingButton.layer.borderColor = UIColor.black.cgColor
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.recordButton.addTarget(self, action: #selector(self.recordTapped), for: .touchUpInside)
                    } else {
                        self.displayRecordError()
                    }
                }
            }
        } catch {
            displayRecordError()
        }
        
        if let session = mySession {
            sessionID = session.ID ?? ""
            sessionHostUID = session.hostUID ?? ""
        } else {
        }
    }
    
    // MARK: Recording Functionality
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            recordingClockLabel.text = "00:00:00"
            
            runTimer()
            
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            controlsCollectionView.isHidden = false
            uploadRecordingButton.isHidden = false
            recordingLabel.isHidden = true
            tapMicrophoneLabel.text = "Tap Microphone to Record"
            
            timer.invalidate()
            self.seconds = 0
        } else {
            displayRecordError()
        }
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            controlsCollectionView.isHidden = true
            uploadRecordingButton.isHidden = true
            recordingLabel.isHidden = false
            
            startRecording()
            
            tapMicrophoneLabel.text = "Tap Again to Stop"
        } else {
            finishRecording(success: true)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: Timer Methods
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MyAudioViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        seconds += 1
        recordingClockLabel.text = timeString(time: TimeInterval(seconds))
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // MARK: Error Alerts
    
    func displayRecordError() {
        let loginAlert = UIAlertController(title: "Unable to Record", message: "Please try again", preferredStyle: UIAlertControllerStyle.alert)
        loginAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(loginAlert, animated: true, completion: nil)
    }
    
    func displayPlayError() {
        let loginAlert = UIAlertController(title: "Unable to Play", message: "Please try again", preferredStyle: UIAlertControllerStyle.alert)
        loginAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(loginAlert, animated: true, completion: nil)
    }
    
    // MARK: Firebase Database Update
    
    private func userDataUpdateWithRecording(recordingLink: String, spinner: UIView) {
        let values = ["audioRecordingURL": recordingLink]
        
        let ref = Database.database().reference()
        let allSessionsKey = ref.child("all sessions").child(sessionID)
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if let error = error {
                print (error)
                UIViewController.removeSpinner(spinner: spinner)
                return
            }
            else {
                // Upload succeeded, set local value
                self.mySession?.audioRecordingURL = recordingLink
                UIViewController.removeSpinner(spinner: spinner)
            }
        })
    }
    
    // MARK: Controls
    
    func playRecording() {
        let recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if audioPlayer == nil {
                let recordingData = try Data(contentsOf: recordingURL)
                audioPlayer = try AVAudioPlayer(data: recordingData, fileTypeHint: AVFileType.m4a.rawValue)
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            } else {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
        } catch {
            displayPlayError()
        }
    }
    
    func pauseRecording() {
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
    
    // MARK: Actions
    
    @IBAction func uploadRecording(_ sender: UIButton) {
        let recordingName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("session_audio").child("\(recordingName).m4a")
        let recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        do {
            let spinner = UIViewController.showSpinner(onView: self.view)
            let recordingData = try Data(contentsOf: recordingURL)
            
            storageRef.putData(recordingData, metadata: nil, completion:
                {(metadata, error) in
                    
                    if let error = error {
                        print(error)
                        UIViewController.removeSpinner(spinner: spinner)
                        return
                    }
                    else {
                        storageRef.downloadURL { (url, error) in
                            guard let recordingFirebaseURL = url?.absoluteString else {
                                UIViewController.removeSpinner(spinner: spinner)
                                return
                            }
                            self.userDataUpdateWithRecording(recordingLink: recordingFirebaseURL, spinner: spinner)
                        }
                    }
            })
        } catch {
        }
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "UnwindToMyActiveSessionFromMyAudio", sender: nil)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UnwindToMyActiveSessionFromMyAudio" {
            let newViewController = segue.destination as! MyActiveSessionViewController
            
            newViewController.mySession = mySession
        }
    }
}

// MARK: Collection View

extension MyAudioViewController: UICollectionViewDataSource {
    func collectionView( _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return controlsCellIds.count
    }
    
    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return controlsCollectionView.dequeueReusableCell(withReuseIdentifier: controlsCellIds[indexPath.item], for: indexPath)
    }
}

extension MyAudioViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return controlsCellSizes[indexPath.item]
    }
    
    // Center the cells
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth : CGFloat = 165.0
        
        let numberOfCells = 1 as CGFloat // There are really 2 but we use 1 here for spacing
        let edgeInsets = (self.controlsCollectionView.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIEdgeInsetsMake(15, edgeInsets, 0, edgeInsets)
        } else {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
}

extension MyAudioViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let controlCellName = controlsCellIds[indexPath.row]
        if controlCellName == "PlayCell" {
            playRecording()
        } else {
            pauseRecording()
        }
    }
}
