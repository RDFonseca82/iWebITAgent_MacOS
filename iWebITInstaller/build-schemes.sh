XCODEPROJ_PATH="./iWebITAgent-macOS.xcodeproj"

SCHEMES=("iWebIT" "iWebITSysTray" "iWebITService")

#xcodebuild clean -project $XCODEPROJ_PATH
#rm -r "~/Library/Developer/Xcode/DerivedData"

for SCHEME in "${SCHEMES[@]}"; do
    xcodebuild build -project $XCODEPROJ_PATH \
                     -scheme $SCHEME \
                     -destination 'platform=macOS' \
                     -configuration Release
done
