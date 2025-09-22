#!/bin/bash
set -e
flutter build appbundle --release
cp build/app/outputs/bundle/release/app-release.aab ~/Downloads/
