//
//  TVShowCollectionViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 21/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit
import AVFoundation

class TVShowCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, TVShowDelegate {

    var loadingView: TVMovieLoadingView!
    var show: TVShow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = show.title
        addLoadingView()
        matchSeasonsIfRequired()
    }

    func addLoadingView() {
        loadingView = Bundle.main.loadNibNamed("TVMovieLoading", owner: self, options: nil)![0] as? TVMovieLoadingView
        loadingView.frame = view.bounds
        loadingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        loadingView.layer.zPosition = 20
        loadingView.isHidden = true
        
        view.addSubview(loadingView)
    }
    
    /**
     Match the seasons to episodes
     */
    func matchSeasonsIfRequired() {
        if show.seasons.isEmpty {
            loadingView.label.text = "Matching Episode Metadata..."
            loadingView.isHidden = false
            show.delegate = self
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            show.convertFilesToEpisodes()
        }
    }
    
    func percentUpdated() {
        loadingView.indicator.setProgress(show.completedPercent, animated: true)
    }
    
    func tvEpisodesLoaded() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        collectionView?.reloadData()
        loadingView.fadeAndHide()
    }
    
    
    
    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let w = view.bounds.width
        
        if w > 400 && w < 700 {
            return CGSize(width: w/2, height: 340)
        } else if w >= 700 && w < 1000 {
            return CGSize(width: w/3, height: 340)
        } else if w >= 1000 {
            return CGSize(width: w/4, height: 340)
        }
        
        // Otherwise return the standard single column
        return CGSize(width: w, height: 340)
    }
    
    // CALLED WHEN THE ORIENTATION CHANGES
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
        
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "seasonHeader", for: indexPath) as! SeasonSectionHeaderCollectionReusableView
            
            let season = show.seasons.sorted(byKeyPath: "number")[indexPath.section]
            
            if season.number > 0 {
                view.label.text = "SEASON \(season.number)"
            } else {
                view.label.text = "OTHER"
            }
            
            return view
            
        }
        
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath)
        
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return show.seasons.sorted(byKeyPath: "number").count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return show.seasons.sorted(byKeyPath: "number")[section].episodes.sorted(byKeyPath: "episodeNo").count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "show", for: indexPath) as! TVShowCollectionViewCell

        let ep = show.seasons.sorted(byKeyPath: "number")[indexPath.section].episodes.sorted(byKeyPath: "episodeNo")[indexPath.item]
        
        if let title = ep.title {
            cell.titleLabel.text = "\(ep.episodeNo). \(title)"
        } else if ep.episodeNo > 0 {
            cell.titleLabel.text = "\(ep.episodeNo). Episode \(ep.episodeNo)"
        } else {
            cell.titleLabel.text = "\(ep.file!.name!)"
        }
        
        if let overview = ep.overview {
            cell.descriptionLabel.text = overview
        } else {
            cell.descriptionLabel.text = "No description available."
        }
        
        cell.imageView.image = UIImage(named: "episode")
        ep.getScreenshot { image in
            cell.imageView.image = image
        }
        
        if let file = ep.file, file.accessed {
            cell.doneView.isHidden = false
        } else {
            cell.doneView.isHidden = true
        }
    
        return cell
    }
    
    
    // MARK: Navigation
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let castHandler = CastHandler.sharedInstance
        
        if let file = show.seasons.sorted(byKeyPath: "number")[indexPath.section].episodes.sorted(byKeyPath: "episodeNo")[indexPath.item].file {
            
            if castHandler.device != nil {
                castHandler.sendFile(file: file) {
                    castHandler.showRemote(sender: self)
                }
            } else {
                let vc = MediaPlayerViewController()
                
                let url = NSURL(string: "\(Putio.api)files/\(file.id)/hls/media.m3u8?oauth_token=\(Putio.accessToken!)&subtitle_key=all")!
                
                vc.file = file
                vc.player = AVPlayer(url: url as URL)
                vc.delegate = PlayerDelegate.sharedInstance
                
                present(vc, animated: true, completion: nil)
            }
            
        }

    }
    
}
