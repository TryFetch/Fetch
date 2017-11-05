//
//  TVCollectionViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 19/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import PutioKit

class TVCollectionViewController: PosterCollectionViewController
//, UIViewControllerPreviewingDelegate
{
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if(traitCollection.forceTouchCapability == .Available){
//            print("registered")
//            registerForPreviewingWithDelegate(self, sourceView: view)
//        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Videos.sharedInstance.sortedTV.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "posterCell", for: indexPath) as! PosterCollectionViewCell
        
        let show = Videos.sharedInstance.sortedTV[indexPath.row]
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TVShowCollectionViewController, let indexPath = collectionView?.indexPathsForSelectedItems?.first {
            vc.show = Videos.sharedInstance.sortedTV[indexPath.row]
        }
    }
    
    
    // MARK: - UIViewControllerPreviewingDelegate
    
//    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
//        
//        print(location)
//        
//        guard let indexPath = collectionView?.indexPathForItemAtPoint(location) else { return nil }
//        
//        print(indexPath)
//        
//        guard let cell = collectionView?.cellForItemAtIndexPath(indexPath) else { return nil }
//        
//        print(cell)
//        
//        guard let seasonView = UIStoryboard(name: "TVMovies", bundle: nil).instantiateViewControllerWithIdentifier("seasonView") as? TVShowCollectionViewController else { return nil }
//        
//        print(seasonView)
//        
//        let show = Videos.sharedInstance.sortedTV[indexPath.item]
//        seasonView.show = show
//        previewingContext.sourceRect = cell.frame
//        return seasonView
//        
//    }
//    
//    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
//        showViewController(viewControllerToCommit, sender: self)
//    }

}
