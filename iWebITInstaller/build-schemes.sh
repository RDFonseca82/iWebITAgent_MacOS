# ./iWebITInstaller/build-schemes.sh && ./iWebITInstaller/build-installer.sh

XCODEPROJ_PATH="./iWebITAgent-macOS.xcodeproj"
XCODEOUTPUT_DIR="/Users/admin/Library/Developer/Xcode/DerivedData/iWebITAgent-macOS-azcpqqwvzksalbehsqrsclupepig/Build/Products/Release"
APP_DIRECTORY="./iWebITInstaller/application"
TARGET_DIRECTORY="Library/Application Support/iWebITAgent"

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

#xcodebuild clean -project $XCODEPROJ_PATH
#rm -r "~/Library/Developer/Xcode/DerivedData"
rm -rf "./iWebITInstaller/application"
mkdir -p "./iWebITInstaller/application/${TARGET_DIRECTORY}"

for ((i=0; i<${#SCHEMES[@]}; i++)); do
    xcodebuild build -project $XCODEPROJ_PATH \
                     -scheme ${SCHEMES[i]} \
                     -destination 'platform=macOS' \
                     -configuration Release
    mv -f "${XCODEOUTPUT_DIR}/${OUTPUT[i]}" "${APP_DIRECTORY}/${MOVE_TO[i]}"

    chown admin:staff "${APP_DIRECTORY}/${MOVE_TO[i]}"
done

exit 0
