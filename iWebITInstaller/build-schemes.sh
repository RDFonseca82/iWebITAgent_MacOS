#!/bin/bash

# Exports

export LC_CTYPE=C
export LANG=C

# ./iWebITInstaller/build-schemes.sh && ./iWebITInstaller/build-installer.sh

XCODEPROJ_PATH="./tmp/src/iWebITAgent-macOS.xcodeproj"
#XCODEOUTPUT_DIR="/Users/admin/Library/Developer/Xcode/DerivedData/iWebITAgent-macOS-azcpqqwvzksalbehsqrsclupepig/Build/Products/Release"
XCODEOUTPUT_DIR="./tmp/derived/Build/Products/Release"
APP_DIRECTORY="./iWebITInstaller/application"
TARGET_DIRECTORY="Library/Application Support/iWebITAgent"

# Move Project to ./tmp/src

rm -rf "./tmp"
mkdir -p "./tmp/src"
mkdir -p "./tmp/derived"

cp -rf "./iWebITAgent" "./tmp/src/iWebITAgent"
cp -rf "./iWebITAgent-macOS.xcodeproj" "${XCODEPROJ_PATH}"
cp -rf "./iWebITService" "./tmp/src/iWebITService"
cp -rf "./iWebITSysTray" "./tmp/src/iWebITSysTray"
cp -rf "./Shared" "./tmp/src/Shared"

find "./tmp/src/" -type f -exec sed -i '' -e 's/__VERSION__/'${VERSION}'/g' {} \;
find "./tmp/src/" -type f -exec sed -i '' -e 's/__PRODUCT__/'${PRODUCT}'/g' {} \;
find "./tmp/src/" -type f -exec sed -i '' -e "s/__PRODUCT_DIR__/${PRODUCT_DIR//\//\\/}/g" {} \;

exit 0
# Build Schemes

rm -rf "./iWebITInstaller/application"
mkdir -p "./iWebITInstaller/application/${TARGET_DIRECTORY}"

SCHEMES=(
    "iWebIT" 
    "iWebITSysTray" 
    "iWebITService"
    )
OUTPUT=(
    "iWebIT.app" 
    "iWebITAgent.app" 
    "iWebITService"
    )
MOVE_TO=(
    "${TARGET_DIRECTORY}/iWebIT" 
    "${TARGET_DIRECTORY}/iWebITAgent" 
    "${TARGET_DIRECTORY}/iWebITService"
    )

for ((i=0; i<${#SCHEMES[@]}; i++)); do
    xcodebuild build -project $XCODEPROJ_PATH \
                     -scheme ${SCHEMES[i]} \
                     -destination 'platform=macOS' \
                     -configuration Release \
                     -derivedDataPath "./tmp/derived"
    mv -f "${XCODEOUTPUT_DIR}/${OUTPUT[i]}" "${APP_DIRECTORY}/${MOVE_TO[i]}"

    chown admin:staff "${APP_DIRECTORY}/${MOVE_TO[i]}"
done

exit 0
