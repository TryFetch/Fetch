//
//  TVMovieViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 19/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class TVMovieViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tvContainer: UIView!
    @IBOutlet weak var movieContainer: UIView!
    var loadingView: TVMovieLoadingView!
    var movieController: MovieCollectionViewController?
    var tvController: TVCollectionViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        automaticallyAdjustsScrollViewInsets = false
        UIApplication.sharedApplication().registerForRemoteNotifications()
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
        
        navigationItem.rightBarButtonItem = CastHandler.sharedInstance.button
        
        tvContainer.layer.zPosition = 10
        movieContainer.layer.zPosition = 10
        
        addLoadingView()
        loadFilesIfRequired()
    }
    
    func addLoadingView() {
        loadingView = NSBundle.mainBundle().loadNibNamed("TVMovieLoading", owner: self, options: nil)[0] as? TVMovieLoadingView
        loadingView.frame = view.bounds
        loadingView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        loadingView.layer.zPosition = 20
        loadingView.hidden = true
        
        view.addSubview(loadingView)
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        if segmentedControl.selectedSegmentIndex == 0 {
            movieContainer.hidden = true
            tvContainer.hidden = false
        } else {
            movieContainer.hidden = false
            tvContainer.hidden = true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedMovies" {
            movieController = segue.destinationViewController as? MovieCollectionViewController
        } else if segue.identifier == "embedTV" {
            tvController = segue.destinationViewController as? TVCollectionViewController
        }
    }
    
    
    // MARK: - File Handling
    
    func loadFilesIfRequired() {
        Videos.sharedInstance.movies = Array(Putio.realm.objects(Movie))
        Videos.sharedInstance.tvShows = Array(Putio.realm.objects(TVShow))
        
        if Videos.sharedInstance.movies.isEmpty && Videos.sharedInstance.tvShows.isEmpty {
            loadFiles()
        } else {
            tmdbLoaded(nil)
        }
    }
    
    func loadFiles() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(tmdbLoaded), name: "TMDBFinished", object: Videos.sharedInstance)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(putioFilesFetched), name: "PutioFinished", object: Videos.sharedInstance)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(progressUpdated), name: "TMDBUpdated", object: Videos.sharedInstance)
        
        movieContainer.hidden = true
        segmentedControl.setEnabled(false, forSegmentAtIndex: 0)
        segmentedControl.setEnabled(false, forSegmentAtIndex: 1)
        segmentedControl.enabled = false
        navigationItem.leftBarButtonItem?.enabled = false
        
        loadingView.indicator.setProgress(0, animated: false)
        loadingView.hidden = false
        
        Videos.sharedInstance.fetch()
    }
    
    func tmdbLoaded(sender: AnyObject?) {
        tvController?.collectionView?.reloadData()
        movieController?.collectionView?.reloadData()
        segmentedControl.setEnabled(true, forSegmentAtIndex: 0)
        segmentedControl.setEnabled(true, forSegmentAtIndex: 1)
        segmentedControl.enabled = true
        segmentedControl.selectedSegmentIndex = 0
        navigationItem.leftBarButtonItem?.enabled = true
        tvContainer.hidden = false
        loadingView.fadeAndHide()
    }
    
    // MARK: - IB Actions
    
    @IBAction func manualSync(sender: AnyObject) {
        if let r = reachability {
            if r.isReachableViaWWAN() {
                let ac = FetchAlertController(title: "Sync Files", message: "Syncing files can take a while. Are you sure you wish to continue on a cellular connection?", preferredStyle: .Alert)

                ac.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { _ in
                    self.executeRefresh()
                }))
                
                ac.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
                self.presentViewController(ac, animated: true, completion: nil)
            } else {
                executeRefresh()
            }
        } else {
            executeRefresh()
        }
    }
    
    func executeRefresh() {
        loadingView?.label.text = "Checking For New Files..."
        loadingView.fadeAndShow()
        loadFiles()
    }
    
    @IBAction func movieSwipe(sender: UISwipeGestureRecognizer) {
        segmentedControl.selectedSegmentIndex = 0
        
        tvContainer.frame.origin.x = -view.frame.width
        tvContainer.hidden = false
        
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseInOut, animations: {
            self.movieContainer.frame.origin.x = self.view.frame.width
            self.tvContainer.frame.origin.x = 0
        }) { _ in
            self.movieContainer.hidden = true
            self.movieContainer.frame.origin.x = 0
        }
        
    }
    
    @IBAction func tvSwipe(sender: UISwipeGestureRecognizer) {
        segmentedControl.selectedSegmentIndex = 1
        
        movieContainer.frame.origin.x = view.frame.width
        movieContainer.hidden = false
        
        UIView.animateWithDuration(0.35, delay: 0, options: .CurveEaseInOut, animations: {
            self.tvContainer.frame.origin.x = -self.view.frame.width
            self.movieContainer.frame.origin.x = 0
        }) { _ in
            self.tvContainer.hidden = true
            self.tvContainer.frame.origin.x = 0
        }
    }
    
    // MARK: - Progress
    
    func putioFilesFetched(sender: AnyObject?) {
        loadingView.label.text = "Matching Files To Metadata..."
        loadingView.indicator.setProgress(0.3, animated: true)
    }
    
    func progressUpdated(sender: AnyObject?) {
        let progress = (Videos.sharedInstance.completedPercent) * 0.7
        loadingView.indicator.setProgress(progress+0.3, animated: true)
    }
    
}
