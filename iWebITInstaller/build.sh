#!/bin/bash

# DONT FORGET TO CHANGE VERSION AND BUILD NUMBER IN XCODE TOO
export VERSION="1.0.0.4"
export PRODUCT="iWebITAgent"
export PRODUCT_DIR="/Library/Application Support/iWebITAgent"

cd "/Users/admin/Desktop/Projetos/iWebITAgent-macOS"

./iWebITInstaller/build-schemes.sh
./iWebITInstaller/build-installer.sh
