//
//  Session.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

public class Session {
    var name: String?
    var genre: String?
    var location: String?
    var host: String?
    var hostImageURL: String?
    var audioRecordingURL: String?
    var code: String?
    var ID: String?
    var hostUID: String?
    var musicians: [Musician]?
    var songs: [String]?
    var isActive: Bool?
}
