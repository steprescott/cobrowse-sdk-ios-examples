#!/bin/bash

# Path to the cbio binary relative to this script or an absolute path
# CBIO_BINARY_PATH="../packages/checkouts/cobrowse-sdk-ios-binary/cbio"
CBIO_BINARY_PATH="/Users/steprescott/projects/cobrowse-sdk-ios-binary/cbio.artifactbundle/cbio-1.0.0-macos/cbio"

# Check if a directory path is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path-to-directory>"
    exit 1
fi

DIRECTORY_PATH="$1"

# Verify if the given argument is a directory
if [ ! -d "$DIRECTORY_PATH" ]; then
    echo "The provided path is not a directory: $DIRECTORY_PATH"
    exit 2
fi

# Verify cbio binary exists
if [ ! -x "$CBIO_BINARY_PATH" ]; then
    echo "cbio binary not found or not executable at expected location: $CBIO_BINARY_PATH"
    exit 3
fi

# Initialize an empty array for storing file paths
swift_files=()

# Find all .swift files and add them to the swift_files array
while IFS= read -r -d '' file; do
    swift_files+=("$file")
done < <(find "$DIRECTORY_PATH" -type f -name "*.swift" -print0)

# Check if any .swift files were found
if [ ${#swift_files[@]} -eq 0 ]; then
    echo "No .swift files found in $DIRECTORY_PATH"
    exit 4
fi

# Pass all .swift file paths as arguments to the cbio redaction command
echo "Processing ${#swift_files[@]} .swift files..."
"$CBIO_BINARY_PATH" redaction "${swift_files[@]}"

echo "Redaction complete for all .swift files in $DIRECTORY_PATH"
