#!/bin/bash

# Exports

export LC_CTYPE=C
export LANG=C

# Parameters
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
TARGET_DIRECTORY="$SCRIPTPATH/target"
PRODUCT="iWebITAgent"
VERSION="2.4.7.0"
PRODUCT_DIR="/Library/Application Support/iWebITAgent"
DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`
LOG_PREFIX="\033[97m[$DATE $TIME]\033[0m"

# Argument validation
if [ -z "${PRODUCT}" ]; then
    echo "Please enter a valid application name for your application"
    echo
    printUsage
    exit 1
else
    echo -e "\033[92m >\033[m \033[96mApplication Name :\033[m    ${PRODUCT}"
fi
if [[ "${VERSION}" =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
    echo -e "\033[92m >\033[m \033[96mApplication Version :\033[m ${VERSION}"
else
    echo "Please enter a valid version for your application (format [0-9].[0-9].[0-9])"
    echo
    printUsage
    exit 1
fi

# Functions
go_to_dir() {
    pushd $1 >/dev/null 2>&1
}

log_info() {
    echo -e "${LOG_PREFIX}\033[94m[INFO]\033[m" $1
}

log_warn() {
    echo -e "${LOG_PREFIX}\033[33m[WARN]\033[m" $1
}

log_error() {
    echo -e "${LOG_PREFIX}\033[91m[ERROR]\033[m" $1
}

deleteInstallationDirectory() {
    log_info "Cleaning $TARGET_DIRECTORY directory."
    rm -rf "$TARGET_DIRECTORY"

    if [[ $? != 0 ]]; then
        log_error "Failed to clean $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

createInstallationDirectory() {
    if [ -d "${TARGET_DIRECTORY}" ]; then
        deleteInstallationDirectory
    fi
    mkdir -pv "$TARGET_DIRECTORY"

    if [[ $? != 0 ]]; then
        log_error "Failed to create $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

copyDarwinDirectory(){
  createInstallationDirectory
  cp -r "$SCRIPTPATH/darwin" "${TARGET_DIRECTORY}/"
  chmod -R 755 "${TARGET_DIRECTORY}/darwin/scripts"
  chmod -R 755 "${TARGET_DIRECTORY}/darwin/Resources"
  chmod 755 "${TARGET_DIRECTORY}/darwin/Distribution"
}

copyBuildDirectory() {
    chmod -R 755 "${TARGET_DIRECTORY}/darwin/scripts/postinstall"

    chmod -R 755 "${TARGET_DIRECTORY}/darwin/Distribution"

    chmod -R 755 "${TARGET_DIRECTORY}/darwin/Resources/"

    rm -rf "${TARGET_DIRECTORY}/darwinpkg"
    mkdir -p "${TARGET_DIRECTORY}/darwinpkg"

    # Copy product to /Library/Application Support/Product
    mkdir -p "${TARGET_DIRECTORY}/darwinpkg"
    cp -a "$SCRIPTPATH"/application/. "${TARGET_DIRECTORY}/darwinpkg/"
    chmod -R 777 "${TARGET_DIRECTORY}/darwinpkg"

    rm -rf "${TARGET_DIRECTORY}/package"
    mkdir -p "${TARGET_DIRECTORY}/package"
    chmod -R 755 "${TARGET_DIRECTORY}/package"

    rm -rf "${TARGET_DIRECTORY}/pkg"
    mkdir -p "${TARGET_DIRECTORY}/pkg"
    chmod -R 755 "${TARGET_DIRECTORY}/pkg"
}

function setPlaceholderValue() {
    find "${TARGET_DIRECTORY}" -type f -exec sed -i '' -e 's/__VERSION__/'${VERSION}'/g' {} \;
    find "${TARGET_DIRECTORY}" -type f -exec sed -i '' -e 's/__PRODUCT__/'${PRODUCT}'/g' {} \;
    find "${TARGET_DIRECTORY}" -type f -exec sed -i '' -e "s/__PRODUCT_DIR__/${PRODUCT_DIR//\//\\/}/g" {} \;
    find "${TARGET_DIRECTORY}" -type f -name "*.DS_Store" -delete
    find "${TARGET_DIRECTORY}" -type f -name "*.gitkeep" -delete
}

function buildPackage() {
    log_info "Application installer package building started.(1/3)"
    pkgbuild --identifier "com.rdfonseca.${PRODUCT}" \
    --ownership preserve \
    --version "${VERSION}" \
    --scripts "${TARGET_DIRECTORY}/darwin/scripts" \
    --root "${TARGET_DIRECTORY}/darwinpkg" \
    "${TARGET_DIRECTORY}/package/${PRODUCT}.pkg" > /dev/null 2>&1
}

function buildProduct() {
    log_info "Application installer product building started.(2/3)"
    productbuild --distribution "${TARGET_DIRECTORY}/darwin/Distribution" \
    --resources "${TARGET_DIRECTORY}/darwin/Resources" \
    --package-path "${TARGET_DIRECTORY}/package" \
    "${TARGET_DIRECTORY}/pkg/$1" > /dev/null 2>&1
}

function createInstaller() {
    log_info "Application installer generation process started.(3 Steps)"
    buildPackage
    buildProduct ${PRODUCT}-macos-installer-x64-${VERSION}.pkg
    log_info "Application installer generation steps finished."
}

function createUninstaller(){
    cp "$SCRIPTPATH/darwin/Resources/uninstall.sh" "${TARGET_DIRECTORY}/darwinpkg/${PRODUCT_DIR}"
}

#Pre-requisites
command -v mvn -v >/dev/null 2>&1 || {
    log_warn "Apache Maven was not found. Please install Maven first."
    # exit 1
}
command -v ballerina >/dev/null 2>&1 || {
    log_warn "Ballerina was not found. Please install ballerina first."
    # exit 1
}

#Main script
log_info "\033[1;97mInstaller generating process started.\033[m"

copyDarwinDirectory
copyBuildDirectory
createUninstaller
setPlaceholderValue
createInstaller

#rm -rf "./iWebITInstaller/application"
#mkdir -p "./iWebITInstaller/application/Library/Application Support/iWebITAgent"


log_info "\033[1;97mInstaller generating process finished.\033[m"
exit 0
