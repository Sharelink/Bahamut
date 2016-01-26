#构建平台通用Framework
FMK_NAME="SharelinkKernel"
SCHEME="SharelinkKernel"
INSTALL_DIR="${PROJECT_DIR}/Products/${FMK_NAME}.framework"
WRK_DIR=build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework
xcodebuild -workspace ../Sharelink.xcworkspace -scheme "${SCHEME}" -configuration "Release" -sdk iphoneos build
xcodebuild -workspace ../Sharelink.xcworkspace -scheme "${SCHEME}" -configuration "Release" -sdk iphonesimulator build
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi
mkdir -p "${INSTALL_DIR}"
cp -R "${DEVICE_DIR}/" "${INSTALL_DIR}"
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_DIR}/${FMK_NAME}"
rm -r "${WRK_DIR}"
open "${INSTALL_DIR}"
