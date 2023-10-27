#!/bin/bash

export VERSION="2.4.9.0"
export PRODUCT="iWebITAgent"
export PRODUCT_DIR="/Library/Application Support/iWebITAgent"

cd "/Users/admin/Desktop/Projetos/iWebITAgent-macOS"

./iWebITInstaller/build-schemes.sh
./iWebITInstaller/build-installer.sh
