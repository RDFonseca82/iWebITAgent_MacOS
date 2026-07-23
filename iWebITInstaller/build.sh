#!/bin/bash

# Version consistency is enforced by scripts/ci/check_version_consistency.py
export VERSION="2.0.0"
export PRODUCT="iWebITAgent"
export PRODUCT_DIR="/Library/Application Support/iWebITAgent"

cd "/Users/admin/Desktop/Projetos/iWebITAgent-macOS"

./iWebITInstaller/build-schemes.sh
./iWebITInstaller/build-installer.sh
