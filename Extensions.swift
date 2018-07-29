//
//  Extensions.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/30/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import AVFoundation

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    func loadImageUsingCacheWithURLString(urlString: String) {
        
        //Some whitespace before the image downloads
        self.image = nil
        
        //See if the cache has an image
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage{
            self.image = cachedImage
            return
        }
        
        //Otherwise
        let url = NSURL(string: urlString)
        URLSession.shared.dataTask(with: url! as URL, completionHandler: {(data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
                
                //Image download was successful
            else {
                print("Successful Image Download")
                DispatchQueue.main.async {
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                        self.image = downloadedImage
                    }
                }
            }
        }).resume()
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
