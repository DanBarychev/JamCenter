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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.isHidden = true
        pauseButton.isHidden = true
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
            print("Setting session ID")
            sessionID = session.ID ?? ""
            sessionHostUID = session.hostUID ?? ""
        } else {
            print("Session nil!")
        }
    }
    
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
            playButton.isHidden = false
            pauseButton.isHidden = false
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
            playButton.isHidden = true
            pauseButton.isHidden = true
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
    
    // MARK: Actions
    
    @IBAction func playRecording(_ sender: UIButton) {
        let recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if audioPlayer == nil {
                /*audioPlayer = try AVAudioPlayer(contentsOf: recordingURL, fileTypeHint: AVFileTypeAppleM4A)*/
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
    
    @IBAction func pauseRecording(_ sender: UIButton) {
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.pause()
        }
    }
    
    @IBAction func uploadRecording(_ sender: UIButton) {
        let recordingName = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("session_audio").child("\(recordingName).m4a")
        let recordingURL = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        do {
            let recordingData = try Data(contentsOf: recordingURL)
            
            storageRef.putData(recordingData, metadata: nil, completion:
                {(metadata, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    else {
                        /*if let recordingFirebaseURL = metadata?.downloadURL()?.absoluteString {
                            self.userDataUpdateWithRecording(recordingLink: recordingFirebaseURL)
                        }*/
                        storageRef.downloadURL { (url, error) in
                            guard let recordingFirebaseURL = url?.absoluteString else {
                                // Uh-oh, an error occurred!
                                return
                            }
                            self.userDataUpdateWithRecording(recordingLink: recordingFirebaseURL)
                        }
                    }
            })
        } catch {
            print("Unable to store recording")
        }
    }
    
    // MARK: Firebase Database Update
    
    private func userDataUpdateWithRecording(recordingLink: String) {
        let values = ["audioRecordingURL": recordingLink]
        
        let ref = Database.database().reference()
        let allSessionsKey = ref.child("all sessions").child(sessionID)
        
        allSessionsKey.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
                return
            }
            else {
                print("Public Copy of Session Updated with Recording")
            }
        })
    }
}
