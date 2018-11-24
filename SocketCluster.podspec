#
# Be sure to run `pod lib lint SocketCluster.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SocketCluster'
  s.version          = '0.1.0'
  s.summary          = 'Native iOS client for SocketCluster http://socketcluster.io/'
  s.description      = 'Native iOS client for SocketCluster http://socketcluster.io/'

  s.homepage         = 'https://github.com/mmoonport/SocketCluster'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Matt Moon' => 'matt@feltapp.com' }
  s.source           = { :git => 'https://github.com/mmoonport/SocketCluster.git', :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'SocketCluster/Classes/**/*'
  s.dependency 'jetfire'
end
