#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rust_lib_zilpay.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rust_lib_zilpay'
  s.version          = '0.0.1'
  s.summary          = 'ZilPay Rust library integration.'
  s.description      = <<-DESC
This pod integrates the core Rust logic for the ZilPay wallet into the macOS application.
                       DESC
  s.homepage         = 'https://zilpay.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ZilPay Team' => 'contact@zilpay.io' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust rust_lib_zilpay',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/librust_lib_zilpay.a"],
  }
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_lib_zilpay.a',
  }
end


