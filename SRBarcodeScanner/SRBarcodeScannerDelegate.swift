//
//  SRBarcodeScannerDelegate.swift
//  SellFormula
//
//  Created by Stephen Radford on 10/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import Foundation

@objc public protocol SRBarcodeScannerDelegate {
    
    /// Should the device fail to create the input (probably because permission wasn't granted), this method will be called.
    optional func failedToCreateDeviceInputWithError(error: NSError)
    
    /// Scanning has started running successfully
    optional func scanningStarted()
    
    /// Scanning has stopped running successfully
    optional func scanningStopped()
    
    /// Called when a barcode has been found
    optional func foundBarcode(barcode: String)
    
}