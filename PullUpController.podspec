Pod::Spec.new do |s|
  s.name             = 'PullUpController'
  s.version          = '0.6.1'
  s.summary          = 'Pull up controller with multiple sticky points like in iOS Maps.'
  s.homepage         = 'https://github.com/MarioIannotta/PullUpController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mario Iannotta' => 'info@marioiannotta.com' }
  s.source           = { :git => 'https://github.com/MarioIannotta/PullUpController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'PullUpController/**/*.swift'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
end
