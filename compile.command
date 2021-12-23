#!/bin/bash

set -ex

# cd script dir
cd "$(dirname "$0")" || exit

GIT_ROOT=$(pwd)

rm -rf build FishUpgrade.app

xcodebuild -project "$GIT_ROOT/FishUpgrade.xcodeproj" \
 -scheme FishUpgrade -configuration Release \
 -derivedDataPath "$GIT_ROOT/build" \
 -destination 'generic/platform=macOS' \
 -sdk macosx \
 clean build \
 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=NO \
 PRODUCT_BUNDLE_IDENTIFIER="wiki.qaq.FishUpgrade" \

cp -R $GIT_ROOT/build/Build/Products/Release/FishUpgrade.app $GIT_ROOT
