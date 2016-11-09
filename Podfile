platform :ios, '9.0'
use_frameworks!

def shared

  pod 'Alamofire', '~> 3.4'
  pod 'AlamofireImage', '~> 2.0'
  pod 'SwiftyJSON', '2.4.0'
  pod 'KeychainAccess', '~> 2.4'
  pod 'RealmSwift'
  
end

target 'Fetch' do

  shared
  pod 'MZFormSheetPresentationController', '~> 2.2.0'
  pod '1PasswordExtension'
  pod 'TUSafariActivity'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'ReachabilitySwift'
  
end

target 'PutioKit' do

  pod 'Downpour', '~> 0.1'

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end