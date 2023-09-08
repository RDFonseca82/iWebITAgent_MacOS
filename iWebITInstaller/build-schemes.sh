XCODEPROJ_PATH="./iWebITAgent-macOS.xcodeproj"
XCODEOUTPUT_DIR="/Users/admin/Library/Developer/Xcode/DerivedData/iWebITAgent-macOS-azcpqqwvzksalbehsqrsclupepig/Build/Products/Release"
APP_DIRECTORY="./iWebITInstaller/application"

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
    "Applications/iWebIT.app" 
    "Library/Application Support/iWebITAgent/iWebITAgent.app" 
    "Library/Application Support/iWebITAgent/iWebITService"
    )

#xcodebuild clean -project $XCODEPROJ_PATH
#rm -r "~/Library/Developer/Xcode/DerivedData"

for ((i=0; i<${#SCHEMES[@]}; i++)); do
    xcodebuild build -project $XCODEPROJ_PATH \
                     -scheme ${SCHEMES[i]} \
                     -destination 'platform=macOS' \
                     -configuration Release
    mv -f "${XCODEOUTPUT_DIR}/${OUTPUT[i]}" "${APP_DIRECTORY}/${MOVE_TO[i]}"
done

exit 0
