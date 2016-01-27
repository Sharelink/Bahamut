FK_NAME=$1
INSTALL_DIR=$2
SIMULATOR_PATH=${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FK_NAME}.framework
DEVICE_PATH=${BUILD_DIR}/${CONFIGURATION}-iphoneos/${FK_NAME}.framework

echo "Product Name:${FK_NAME}"
echo "Config:${CONFIGURATION}"

echo "Simulator Path:${SIMULATOR_PATH}"
echo "Device Path:${DEVICE_PATH}"

if [ ! -d $SIMULATOR_PATH ]; then
  echo “No Simulator Version Release, Build Simulator First”
  exit 1
fi

if [ ! -d $DEVICE_PATH ]; then
  echo “No Device Version Release, Build Device First”
  exit 1
fi

if [ ! -d $INSTALL_DIR ]; then
mkdir -p ${INSTALL_DIR}
fi

lipo -create ${SIMULATOR_PATH}/${FK_NAME} ${DEVICE_PATH}/${FK_NAME} -output $INSTALL_DIR/$FK_NAME

FK_PRODUCT=${INSTALL_DIR}/${FK_NAME}.framework

if [ -d $FK_PRODUCT ]; then
  rm -R $FK_PRODUCT
fi

cp -R -P $SIMULATOR_PATH ${INSTALL_DIR}
cp -R -P $DEVICE_PATH ${INSTALL_DIR}

mv $INSTALL_DIR/$FK_NAME $FK_PRODUCT