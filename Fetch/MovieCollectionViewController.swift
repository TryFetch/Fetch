//
//  MovieCollectionViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 19/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit
import AVKit
import AVFoundation

class MovieCollectionViewController: PosterCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Videos.sharedInstance.sortedMovies.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "posterCell", for: indexPath) as! PosterCollectionViewCell
        
        let show = Videos.sharedInstance.sortedMovies[indexPath.row]
        
        if let poster = show.poster {
            cell.poster.image = poster
        } else {
            cell.poster.image = UIImage(named: "poster")
            show.getPoster { poster in
                cell.poster.image = poster
            }
        }
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let castHandler = CastHandler.sharedInstance
        let movie = Videos.sharedInstance.sortedMovies[indexPath.item]
        let file = movie.files[0]
        
        if castHandler.device != nil {
            castHandler.sendFile(file) {
                castHandler.showRemote(self)
            }
        } else {
            let vc = MediaPlayerViewController()
            
            let url = URL(string: "\(Putio.api)files/\(file.id)/hls/media.m3u8?oauth_token=\(Putio.accessToken!)&subtitle_key=all")!
            
            vc.file = file
            vc.player = AVPlayer(url: url)
            vc.delegate = PlayerDelegate.sharedInstance
            
            present(vc, animated: true, completion: nil)
        }
        
    }
    
}
