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
        
        logoImageView.image = logoImageView.image!.withRenderingMode(.alwaysTemplate)
        logoImageView.tintColor = .white
        
        scanner.delegate = self
        
        if scanner.previewLayer != nil {
            scanner.previewLayer.frame = view.frame
            scanner.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            scanner.layoutIfNeeded()
        } else {
            let v = NoResultsView(frame: view.frame, text: "Allow camera access in Settings.")
            v.backgroundColor = .groupTableViewBackground
            view.addSubview(v)
            v.isHidden = false
        }
        
        let sound = Bundle.main.path(forResource: "success", ofType: "wav")
        let url = URL(fileURLWithPath: sound!)
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID!)
        
        scanner.startScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        soundID = nil
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    // MARK: - SRBarcodeScannerDelegate
    
    func foundBarcode(barcode: String) {
        
        scanner.stopScanning()
        
        Alamofire.request("https://ftch.in/exchange-tokens/\(barcode)", method: .put, parameters: [
            "secret" : Putio.secret,
            "access_token" : Putio.accessToken!
        ])
        
        playSound()
        
        navigationController?.popToRootViewController(animated: true)

    }
    
    func failedToCreateDeviceInputWithError(error: NSError) {
        print(error)
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(soundID!)
    }

}
