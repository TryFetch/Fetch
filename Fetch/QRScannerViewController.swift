//
//  QRScannerViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 13/09/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import SRBarcodeScanner
import Alamofire
import PutioKit

class QRScannerViewController: UIViewController, SRBarcodeScannerDelegate {

    @IBOutlet weak var scanner: SRBarcodeScanner!
    @IBOutlet weak var logoImageView: UIImageView!
    var soundID: SystemSoundID? = 0
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoImageView.image = logoImageView.image!.imageWithRenderingMode(.AlwaysTemplate)
        logoImageView.tintColor = .whiteColor()
        
        scanner.delegate = self
        
        if scanner.previewLayer != nil {
            scanner.previewLayer.frame = view.frame
            scanner.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
            scanner.layoutIfNeeded()
        } else {
            let v = NoResultsView(frame: view.frame, text: "Allow camera access in Settings.")
            v.backgroundColor = .groupTableViewBackgroundColor()
            view.addSubview(v)
            v.hidden = false
        }
        
        let sound = NSBundle.mainBundle().pathForResource("success", ofType: "wav")
        let url = NSURL.fileURLWithPath(sound!)
        AudioServicesCreateSystemSoundID(url, &soundID!)
        
        scanner.startScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        soundID = nil
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    
    // MARK: - SRBarcodeScannerDelegate
    
    func foundBarcode(barcode: String) {
        
        scanner.stopScanning()
        
        Alamofire.request(.PUT, "https://ftch.in/exchange-tokens/\(barcode)", parameters: [
            "secret" : Putio.secret,
            "access_token" : Putio.accessToken!
        ])
        
        playSound()
        
        navigationController?.popToRootViewControllerAnimated(true)

    }
    
    func failedToCreateDeviceInputWithError(error: NSError) {
        print(error)
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(soundID!)
    }

}
