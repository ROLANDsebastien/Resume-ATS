#!/bin/bash

# Auto-build script for Resume-ATS
# Runs xcodebuild and checks for errors

echo "Starting auto-build..."

# Run xcodebuild (assuming project is in Resume-ATS/)
cd /Users/rolandsebastien/Developer/Resume-ATS/Resume-ATS

OUTPUT=$(xcodebuild build 2>&1)
EXIT_CODE=$?

echo "$OUTPUT"

if echo "$OUTPUT" | grep -i "error" > /dev/null; then
    echo "Build failed: Errors detected in output."
    exit 1
else
    echo "Build succeeded."
    exit 0
fi