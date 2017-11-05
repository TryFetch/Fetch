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
        UIApplication.shared.registerForRemoteNotifications()
        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        navigationItem.rightBarButtonItem = CastHandler.sharedInstance.button
        
        tvContainer.layer.zPosition = 10
        movieContainer.layer.zPosition = 10
        
        addLoadingView()
        loadFilesIfRequired()
    }
    
    func addLoadingView() {
        loadingView = Bundle.main.loadNibNamed("TVMovieLoading", owner: self, options: nil)![0] as? TVMovieLoadingView
        loadingView.frame = view.bounds
        loadingView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        loadingView.layer.zPosition = 20
        loadingView.isHidden = true
        
        view.addSubview(loadingView)
    }
    
    @IBAction func segmentChanged(_ sender: AnyObject) {
        if segmentedControl.selectedSegmentIndex == 0 {
            movieContainer.isHidden = true
            tvContainer.isHidden = false
        } else {
            movieContainer.isHidden = false
            tvContainer.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedMovies" {
            movieController = segue.destination as? MovieCollectionViewController
        } else if segue.identifier == "embedTV" {
            tvController = segue.destination as? TVCollectionViewController
        }
    }
    
    
    // MARK: - File Handling
    
    func loadFilesIfRequired() {
        Videos.sharedInstance.movies = Array(Putio.realm.objects(Movie.self))
        Videos.sharedInstance.tvShows = Array(Putio.realm.objects(TVShow.self))
        
        if Videos.sharedInstance.movies.isEmpty && Videos.sharedInstance.tvShows.isEmpty {
            loadFiles()
        } else {
            tmdbLoaded(nil)
        }
    }
    
    func loadFiles() {
        NotificationCenter.default.addObserver(self, selector: #selector(tmdbLoaded), name: NSNotification.Name(rawValue: "TMDBFinished"), object: Videos.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(putioFilesFetched), name: NSNotification.Name(rawValue: "PutioFinished"), object: Videos.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(progressUpdated), name: NSNotification.Name(rawValue: "TMDBUpdated"), object: Videos.sharedInstance)
        
        movieContainer.isHidden = true
        segmentedControl.setEnabled(false, forSegmentAt: 0)
        segmentedControl.setEnabled(false, forSegmentAt: 1)
        segmentedControl.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        loadingView.indicator.setProgress(0, animated: false)
        loadingView.isHidden = false
        
        Videos.sharedInstance.fetch()
    }
    
    func tmdbLoaded(_ sender: AnyObject?) {
        tvController?.collectionView?.reloadData()
        movieController?.collectionView?.reloadData()
        segmentedControl.setEnabled(true, forSegmentAt: 0)
        segmentedControl.setEnabled(true, forSegmentAt: 1)
        segmentedControl.isEnabled = true
        segmentedControl.selectedSegmentIndex = 0
        navigationItem.leftBarButtonItem?.isEnabled = true
        tvContainer.isHidden = false
        loadingView.fadeAndHide()
    }
    
    // MARK: - IB Actions
    
    @IBAction func manualSync(_ sender: AnyObject) {
        if let r = reachability {
            if r.isReachableViaWWAN {
                let ac = FetchAlertController(title: "Sync Files", message: "Syncing files can take a while. Are you sure you wish to continue on a cellular connection?", preferredStyle: .alert)

                ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    self.executeRefresh()
                }))
                
                ac.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(ac, animated: true, completion: nil)
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
    
    @IBAction func movieSwipe(_ sender: UISwipeGestureRecognizer) {
        segmentedControl.selectedSegmentIndex = 0
        
        tvContainer.frame.origin.x = -view.frame.width
        tvContainer.isHidden = false
        
        UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.movieContainer.frame.origin.x = self.view.frame.width
            self.tvContainer.frame.origin.x = 0
        }) { _ in
            self.movieContainer.isHidden = true
            self.movieContainer.frame.origin.x = 0
        }
        
    }
    
    @IBAction func tvSwipe(_ sender: UISwipeGestureRecognizer) {
        segmentedControl.selectedSegmentIndex = 1
        
        movieContainer.frame.origin.x = view.frame.width
        movieContainer.isHidden = false
        
        UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.tvContainer.frame.origin.x = -self.view.frame.width
            self.movieContainer.frame.origin.x = 0
        }) { _ in
            self.tvContainer.isHidden = true
            self.tvContainer.frame.origin.x = 0
        }
    }
    
    // MARK: - Progress
    
    func putioFilesFetched(_ sender: AnyObject?) {
        loadingView.label.text = "Matching Files To Metadata..."
        loadingView.indicator.setProgress(0.3, animated: true)
    }
    
    func progressUpdated(_ sender: AnyObject?) {
        let progress = (Videos.sharedInstance.completedPercent) * 0.7
        loadingView.indicator.setProgress(progress+0.3, animated: true)
    }
    
}
