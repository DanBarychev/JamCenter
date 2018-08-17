//
//  AudioViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/9/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Cancel Icon from https://icons8.com/icon/3062/Cance
//

import UIKit
import AVFoundation

class AudioViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var recordingClockLabel: UILabel!
    @IBOutlet weak var noRecordingLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var currentSession: Session?
    var recordingURL = String()
    var audioPlayer: AVPlayer!
    var seconds = 0
    var timer = Timer()
    var playTapped = false
    var pauseTapped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = currentSession {
            print("In the Session")
            recordingURL = session.audioRecordingURL ?? ""
            if recordingURL == "" {
                noRecordingLabel.isHidden = false
                recordingClockLabel.isHidden = true
                playButton.isHidden = true
                pauseButton.isHidden = true
                stopButton.isHidden = true
            } else {
                noRecordingLabel.isHidden = true
                recordingClockLabel.isHidden = false
                playButton.isHidden = false
                pauseButton.isHidden = false
                stopButton.isHidden = false
            }
        }
    }
    
    // MARK: Error Handling
    
    func displayPlayError() {
        let loginAlert = UIAlertController(title: "Unable to Play", message: "Please try again", preferredStyle: UIAlertControllerStyle.alert)
        loginAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(loginAlert, animated: true, completion: nil)
    }
    
    // MARK: Timer Methods
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(MyAudioViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if audioPlayer != nil && audioPlayer.isPlaying {
            seconds += 1
            recordingClockLabel.text = timeString(time: TimeInterval(seconds))
        } else if !pauseTapped {
            seconds = 0
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // MARK: Actions
    
    @IBAction func playRecording(_ sender: UIButton) {
        let remoteURL = NSURL(string: recordingURL)! as URL
        
        if audioPlayer == nil {
            recordingClockLabel.text = "00:00:00"
            
            audioPlayer = AVPlayer(url: remoteURL)
            audioPlayer.volume = 1
            audioPlayer.play()
        }
        
        if !playTapped {
            runTimer()
        }

        playTapped = true
        pauseTapped = false
    }
    
    @IBAction func pauseRecording(_ sender: UIButton) {
        if audioPlayer != nil && audioPlayer.isPlaying {
            audioPlayer.pause()
            
            pauseTapped = true
        }
    }
    
    @IBAction func stopRecording(_ sender: UIButton) {
        if audioPlayer != nil {
            audioPlayer.pause()
            audioPlayer = nil
            playTapped = false
            
            timer.invalidate()
            seconds = 0
        }
    }
}
