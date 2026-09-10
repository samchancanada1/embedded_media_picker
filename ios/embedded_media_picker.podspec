#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint embedded_media_picker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'embedded_media_picker'
  s.version          = '0.0.1'
  s.summary          = 'Android embedded media picker with cross-platform fallback.'
  s.description      = <<-DESC
Flutter plugin for Android embedded photo picker and iOS PHPicker fallback.
                       DESC
  s.homepage         = 'https://github.com/hiutungchan/embedded_media_picker'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Sam Chan'
  s.source           = { :path => '.' }
  s.source_files = 'embedded_media_picker/Sources/embedded_media_picker/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'embedded_media_picker_privacy' => ['embedded_media_picker/Sources/embedded_media_picker/PrivacyInfo.xcprivacy']}
end
