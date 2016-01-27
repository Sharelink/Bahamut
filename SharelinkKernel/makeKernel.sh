xcodebuild -workspace ../Sharelink.xcworkspace -scheme SharelinkKernel -sdk iphoneos -destination 'platform=iOS,name=generic' build
xcodebuild -workspace ../Sharelink.xcworkspace -scheme SharelinkKernel -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6' build
