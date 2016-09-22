#
# Be sure to run `pod lib lint CRUDRecord.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CRUDRecord'
  s.version          = '0.1.0'
  s.summary          = 'A short description of CRUDRecord.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/<GITHUB_USERNAME>/CRUDRecord'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Vlad Gorbenko' => 'mojidabckuu.22.06.92@gmail.com' }
  s.source           = { :git => 'https://github.com/mojidabckuu/CRUDRecord.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'CRUDRecord/Classes/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'ApplicationSupport'
  s.dependency 'Alamofire', '~> 4.0'
end
