//
//  SRBarcodeScanner.swift
//  SellFormula
//
//  Created by Stephen Radford on 10/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import AVFoundation

public class SRBarcodeScanner: UIView, AVCaptureMetadataOutputObjectsDelegate {
    
    /// Delegate where we can fire off all the notifications to
    public var delegate: SRBarcodeScannerDelegate?
    
    /// The capture session that will let us launch the camera
    let captureSession = AVCaptureSession()
    
    /// The capture device we're gonna be using. This will be the back camera by default.
    public var captureDevice: AVCaptureDevice?
    
    /// The output we're gonna capture
    public var captureOutput: AVCaptureMetadataOutput?
    
    /// This layer displays the current video capture session
    public var previewLayer: AVCaptureVideoPreviewLayer!
    
    /// This is the highlight view layer that is primarily for debugging purposes
    public var highlightView = UIView()
    
    /// Does the camera have a back camera?
    public class var hasBackCamera: Bool {
        get {
            var haveCamera = false
            let devices = AVCaptureDevice.devices()
            for device in devices {
                if device.hasMediaType(AVMediaTypeVideo) {
                    if device.position == .Back {
                        haveCamera = true
                    }
                }
            }
            return haveCamera
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCaptureSession()
    }
    
    
    // MARK: - Capture Session
    
    /// Setup the capture session by creating the capture device and adding it to the session
    public func setupCaptureSession() {
        
        // Check if we have a back camera and then set it as the device
        if SRBarcodeScanner.hasBackCamera {
            captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        }
        
        // Create I/O
        if createInput() {
            createOutput()
            setupPreview()
            setupHighlightView()
        }
        
    }
    
    /// Setup the device input
    func createInput() -> Bool {
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            return true
        } catch {
            delegate?.failedToCreateDeviceInputWithError?(error as NSError)
            return false
        }

    }
    
    /// Create the device output
    func createOutput() {
        captureOutput = AVCaptureMetadataOutput()
        captureOutput!.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureSession.addOutput(captureOutput!)
        
        // See: https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVMetadataMachineReadableCodeObject_Class/index.html#//apple_ref/doc/constant_group/Machine_Readable_Object_Types
        
        captureOutput!.metadataObjectTypes = [
            AVMetadataObjectTypeQRCode
        ]
        
        // TODO: Look to output this to another GCD queue
    }
    
    /// Create the preview layer and set the gravity
    func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer.frame = frame
        layer.addSublayer(previewLayer)
    }
    
    /// Create the highlight view
    func setupHighlightView() {
        highlightView.layer.borderWidth = 2
        highlightView.layer.borderColor = UIColor.redColor().CGColor
        addSubview(highlightView)
    }
    
    
    // MARK: - Actions
    
    /// Start scanning barcodes
    public func startScanning() {
        captureSession.startRunning()
        delegate?.scanningStarted?()
    }
    
    /// Stop scanning barcodes
    public func stopScanning() {
        captureSession.stopRunning()
        delegate?.scanningStopped?()
    }
    
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects.count > 0 {
            let string = metadataObjects[0].stringValue as String
            delegate?.foundBarcode?(string)
        }
        
    }
    
}