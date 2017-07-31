//
//  SessionTableViewCell.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Circle Icon from https://icons8.com/icon/8097/Active-State-Filled

import UIKit

class SessionTableViewCell: UITableViewCell {
    
    // MARK: Properties
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var activeLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var activeImageView: UIImageView!
    @IBOutlet weak var roleImageView: UIImageView!
}
