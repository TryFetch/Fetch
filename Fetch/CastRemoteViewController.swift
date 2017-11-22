//
//  CastRemoteViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 01/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import PutioKit

class CastRemoteViewController: UIViewController, CastHandlerDelegate {
    
    /// The file we're currently casting
    var file: File?
    
    /// Play image
    let playImage: UIImage = UIImage(named: "fetch-play")!
    
    /// Pause image
    let pauseImage: UIImage = UIImage(named: "fetch-pause")!
    
    /// Reference to the shared casthandler instance. Set here so we can dump it later.
    var castHandler: CastHandler?
    
    /// Reference to the done button
    @IBOutlet weak var doneBtn: UIButton!
    
    /// Reference to the stop button
    @IBOutlet weak var stopBtn: UIButton!
    
    /// Activity indicator in the image section
    @IBOutlet weak var imageLoading: UIActivityIndicatorView!
    
    /// Screenshot of the file
    @IBOutlet weak var image: UIImageView!
    
    /// Play button
    @IBOutlet weak var playBtn: UIButton!
    
    /// Forward button
    @IBOutlet weak var fwdBtn: UIButton!
    
    /// Rewind Button
    @IBOutlet weak var rwdBtn: UIButton!
    
    /// Title Label
    @IBOutlet weak var titleLabel: UILabel!
    
    /// Scrub Bar
    @IBOutlet weak var scrubBar: UISlider!
    
    /// Duration Label
    @IBOutlet weak var durationLabel: UILabel!
    
    /// Position Label
    @IBOutlet weak var positionLabel: UILabel!
    
    /// The switch for turning subtitles on and off
    @IBOutlet weak var subtitleSwith: UISwitch!
    
    /// Container view for the subtitle switch and label
    @IBOutlet weak var subtitleContainer: UIView!
    
    /// Duration of the currently playing file
    var duration: TimeInterval = 0
    
    /// Position of the currently playing file
    var position: TimeInterval = 0
    
    /// Interval timer for the position of the video
    var positionTimer: Timer?
    
    /// Timeout for GCD
    var gcdTimeout: Int = 0
    
    /// Timeout for GCD
    var gcdTimeout2: Int = 0
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        titleLabel.text = file!.name
        
        castHandler = CastHandler.sharedInstance
        castHandler?.delegate = self
        
//        JPSVolumeButtonHandler(upBlock: { () -> Void in
//            println("volume up")
//        }, downBlock: { () -> Void in
//            println("volume down")
//        })
        
        setupSubtitles()
        updatePlayPauseImage()
        setupImage()
        setupButtons()
        setupSlider()
        getDuration()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getPosition()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        castHandler = nil
        positionTimer?.invalidate()
        positionTimer = nil
        file = nil
        
        super.viewDidDisappear(animated)
    }
    
    override func applicationFinishedRestoringState() {
        getPosition()
    }
    
    
    // MARK: - Play/Pause Button
    
    /// Check the current play state of the CastHandler and update the image appropriately
    func updatePlayPauseImage() {
        if castHandler!.isPlaying {
            playBtn.setImage(pauseImage, for: .normal)
        } else {
            playBtn.setImage(playImage, for: .normal)
        }
    }
    
    
    // MARK: - Done/Stop buttons
    
    /// Set the style for the done and stop buttons
    func setupButtons() {
        doneBtn.clipsToBounds = true
        doneBtn.layer.cornerRadius = 5
        doneBtn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        doneBtn.layer.borderColor = UIColor.white.cgColor
        doneBtn.layer.borderWidth = 1
        doneBtn.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0.25)
        
        stopBtn.clipsToBounds = true
        stopBtn.layer.cornerRadius = 5
        stopBtn.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        stopBtn.layer.borderColor = UIColor.white.cgColor
        stopBtn.layer.borderWidth = 1
        stopBtn.backgroundColor = UIColor(red:1, green:1, blue:1, alpha:0.25)
    }
    
    
    // MARK: - Position & Duration Label
    
    /// Set the string on the position label
    func updatePositionLabel() {
        durationLabel.text = "\(stringFromTimeInterval(interval: duration))"
        positionLabel.text = "\(stringFromTimeInterval(interval: position))"
    }
    
    /// Convert the time interval into h:i:s
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    
    // MARK: - Scrub Bar
    
    /// Update the max value with the duration and the current value with the position
    func updateScrubBar() {
        scrubBar.isEnabled = true
        scrubBar.maximumValue = Float(duration)
        scrubBar.value = Float(position)
    }
    
    /// Change the image to a smaller thumb on the slider
    func setupSlider() {
        let image = UIImage(named: "fetch-thumb")
        scrubBar.setThumbImage(image, for: [])
        
//        let active = UIImage(named: "fetch-thumb-active")
//        scrubBar.setThumbImage(active, forState: .Highlighted)
    }
    
    
    // MARK: - Image
    
    /// Add the gradient mask and load the image from the server
    func setupImage() {
        let gradientMask = CAGradientLayer()
        gradientMask.colors = [
            UIColor.white.cgColor,
            UIColor.clear.cgColor
        ]
        gradientMask.frame = image.bounds
        gradientMask.locations = [0.0, 0.45]
        
        image.layer.mask = gradientMask
        
        self.imageLoading.startAnimating()
        
        fetchImage()
    }
    
    /// Fetch the image from the server asynchronously
    func fetchImage() {
        Alamofire.request(file!.screenshot!, method: .get)
            .response { (result) -> Void in
                self.imageLoading.stopAnimating()
                self.imageLoading.isHidden = true
                self.image.image = UIImage(data: result.data!)
            }
    }
    
    /// Setup the subtitles switch
    func setupSubtitles() {
        if castHandler?.device?.service(withName: "Chromecast") != nil {
            subtitleSwith.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        } else {
            subtitleContainer.isHidden = true
        }
    }
    
    
    // MARK: - Position and Duration
    
    /// Fetch the current position from the device.
    /// We only need to do this at the beginning and in state changes otherwise we can use an interval to set the time every second.
    func getPosition() {
        castHandler?.launchObject?.mediaControl.getPositionWithSuccess({ (position) -> Void in
            self.position = position
            self.setPositionIntervalTimer()
            }, failure: { (error) -> Void in
                print(error)
                self.delay(delay: 1) {
                    self.getPosition()
                }
        })
    }
    
    /// Fetch the duration from the launchObject and set it to the property in the class
    func getDuration() {
        castHandler?.launchObject?.mediaControl.getDurationWithSuccess({ (duration) -> Void in
            if duration == 0 {
                self.delay(delay: 1) {
                    self.getDuration()
                }
            } else {
                self.duration = duration
                self.getPosition()
                self.enableSubtitleSwitch()
            }
        }, failure: { (error) -> Void in
            print(error)
            self.gcdTimeout += 1
            if self.gcdTimeout < 20 {
                self.delay(delay: 1) {
                    self.getDuration()
                }
            }
        })
    }
    
    /// Setup a timer that will add 1s onto the position every second
    func setPositionIntervalTimer() {
        positionTimer?.invalidate() // Invalidate anything that was already there before we replace it
        positionTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(addOneSecondToPosition), userInfo: nil, repeats: true)
    }
    
    /// Add one second to the position time and then update the label + scrub bar
    func addOneSecondToPosition(sender: AnyObject?) {
        position += 1
        self.updateScrubBar()
        self.updatePositionLabel()
    }
    
    /// Seek to a specific position
    func seekToPosition(position: TimeInterval) {
        positionTimer?.invalidate()
        positionTimer = nil
        self.position = position
        
        castHandler?.launchObject?.mediaControl.seek(position, success: { (sender) -> Void in
            self.delay(delay: 1.5) {
                self.getPosition()
            }
            }) { (error) -> Void in
                print(error)
        }
    }
    
    
    // MARK: - Actions
    
    /// Hide the controller
    @IBAction func dismissView(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Play/pause the currently playing file
    @IBAction func playPause(_ sender: AnyObject) {
        
        if castHandler!.isPlaying {
            castHandler?.launchObject?.mediaControl.pause(success: { (sender) -> Void in
                self.positionTimer?.invalidate()
                self.positionTimer = nil
                self.castHandler?.isPlaying = false
            }, failure: nil)
        } else {
            castHandler?.launchObject?.mediaControl.play(success: { (sender) -> Void in
                self.castHandler?.isPlaying = true
                self.getPosition()
            }, failure: nil)
        }
        
        updatePlayPauseImage()
    }
    
    /// Shut this shit dowwwwwn!
    @IBAction func stop(_ sender: AnyObject) {
        castHandler?.stop()
        dismissView(sender)
    }
    
    /// Seek to a specific position when the scrub bar is moved.
    @IBAction func seekTo(_ sender: AnyObject) {
        positionTimer?.invalidate()
        seekToPosition(position: TimeInterval(scrubBar.value))
    }
    
    /// Fast forward 30 seconds
    @IBAction func forward30(_ sender: AnyObject) {
        seekToPosition(position: position+30)
    }
    
    /// Rewind 30 seconds
    @IBAction func rewind30(_ sender: AnyObject) {
        seekToPosition(position: position-30)
    }
    
    /// Touch down and set the alpha of the button to less than 1
    @IBAction func touchDown(_ sender: AnyObject) {
        let btn = sender as! UIButton
        btn.alpha = 0.8
    }
    
    /// Set alpha back to 1
    @IBAction func alphaUp(_ sender: AnyObject) {
        let btn = sender as! UIButton
        btn.alpha = 1
    }
    
    /// Turn the subtitles on or off
    @IBAction func switchSubtitles(_ sender: AnyObject) {
        
        let service = castHandler!.launchObject!.session.service as! CastService
        
        if subtitleSwith.isOn {
            print("------- SUBTITLES ON ----------")
            service.castMediaControlChannel.setActiveTrackIDs([42]) // hardcoded 42!!!!
            castHandler?.subtitlesEnabled = true
        } else {
            print("------- SUBTITLES OFF ----------")
            service.castMediaControlChannel.setActiveTrackIDs([])
            castHandler?.subtitlesEnabled = false
        }
    }
    
    /// Disable subtitles when the video first loads IF it's a chromecast
    func disableSubtitles() {
    
        if castHandler?.device?.service(withName: "Chromecast") == nil {
            return
        }
        
        castHandler?.launchObject?.mediaControl.getDurationWithSuccess({ (duration) -> Void in
           
            let service = self.castHandler!.launchObject!.session.service as! CastService
            service.castMediaControlChannel.setActiveTrackIDs([])
            
        }, failure: { (error) -> Void in
            self.gcdTimeout2 += 1
            if self.gcdTimeout2 < 20 {
                self.delay(delay: 1) {
                    self.disableSubtitles()
                }
            }
        })
        
    }
    
    /// Enable the subtitles switch and set the state
    func enableSubtitleSwitch() {
        subtitleSwith.isOn = castHandler!.subtitlesEnabled
        subtitleSwith.isEnabled = true
    }
    
    // MARK: - CastHandlerDelegate
    
    func launchObjectSuccess() {
        delay(delay: 1.5) {
            self.getDuration()
            self.disableSubtitles()
        }
        print("launch object success!", terminator: "")
    }
    
}
