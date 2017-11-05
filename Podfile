platform :ios, '9.0'
use_frameworks!

def shared

  pod 'Alamofire', '~> 4.5'
  pod 'AlamofireImage', '~> 3.2'
  pod 'SwiftyJSON', '~> 3.1'
  pod 'KeychainAccess', '~> 3.0'
  pod 'RealmSwift'
  pod 'Downpour', '~> 0.2'
  
end

target 'Fetch' do

  shared
  pod 'MZFormSheetPresentationController', '~> 2.2.0'
  pod '1PasswordExtension'
  pod 'TUSafariActivity'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'ReachabilitySwift', '~> 3.0'
  
end

target 'PutioKit' do
  
  shared

end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
