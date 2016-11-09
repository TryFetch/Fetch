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
        loadingView = NSBundle.mainBundle().loadNibNamed("TVMovieLoading", owner: self, options: nil)![0] as? TVMovieLoadingView
        loadingView.frame = view.bounds
        loadingView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        loadingView.layer.zPosition = 20
        loadingView.hidden = true
        
        view.addSubview(loadingView)
    }
    
    /**
     Match the seasons to episodes
     */
    func matchSeasonsIfRequired() {
        if show.seasons.isEmpty {
            loadingView.label.text = "Matching Episode Metadata..."
            loadingView.hidden = false
            show.delegate = self
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            show.convertFilesToEpisodes()
        }
    }
    
    func percentUpdated() {
        loadingView.indicator.setProgress(show.completedPercent, animated: true)
    }
    
    func tvEpisodesLoaded() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        collectionView?.reloadData()
        loadingView.fadeAndHide()
    }
    
    
    
    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let w = view.bounds.width
        
        if w > 400 && w < 700 {
            return CGSizeMake(w/2, 340)
        } else if w >= 700 && w < 1000 {
            return CGSizeMake(w/3, 340)
        } else if w >= 1000 {
            return CGSizeMake(w/4, 340)
        }
        
        // Otherwise return the standard single column
        return CGSizeMake(w, 340)
    }
    
    // CALLED WHEN THE ORIENTATION CHANGES
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
        
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "seasonHeader", forIndexPath: indexPath) as! SeasonSectionHeaderCollectionReusableView
            
            let season = show.seasons.sorted("number")[indexPath.section]
            
            if season.number > 0 {
                view.label.text = "SEASON \(season.number)"
            } else {
                view.label.text = "OTHER"
            }
            
            return view
            
        }
        
        return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "sectionFooter", forIndexPath: indexPath)
        
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return show.seasons.sorted("number").count
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return show.seasons.sorted("number")[section].episodes.sorted("episodeNo").count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("show", forIndexPath: indexPath) as! TVShowCollectionViewCell

        let ep = show.seasons.sorted("number")[indexPath.section].episodes.sorted("episodeNo")[indexPath.item]
        
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
        
        if let file = ep.file where file.accessed {
            cell.doneView.hidden = false
        } else {
            cell.doneView.hidden = true
        }
    
        return cell
    }
    
    
    // MARK: Navigation
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let castHandler = CastHandler.sharedInstance
        if let file = show.seasons.sorted("number")[indexPath.section].episodes.sorted("episodeNo")[indexPath.item].file {
            
            if castHandler.device != nil {
                castHandler.sendFile(file) {
                    castHandler.showRemote(self)
                }
            } else {
                let vc = MediaPlayerViewController()
                
                let url = NSURL(string: "\(Putio.api)files/\(file.id)/hls/media.m3u8?oauth_token=\(Putio.accessToken!)&subtitle_key=all")!
                
                vc.file = file
                vc.player = AVPlayer(URL: url)
                vc.delegate = PlayerDelegate.sharedInstance
                
                presentViewController(vc, animated: true, completion: nil)
            }
            
        }

    }
    
}
