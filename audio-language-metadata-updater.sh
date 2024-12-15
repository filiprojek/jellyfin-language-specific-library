#!/bin/bash

# Root directory (current working directory)
ROOT_DIR="$(pwd)"

# Video format (can be changed from 'avi' to other formats like 'mp4', 'mkv', etc.)
VIDEO_FORMAT="avi"

# Function to process each video file
process_file() {
  local input_file="$1"
  local temp_file="${input_file%.${VIDEO_FORMAT}}_temp.${VIDEO_FORMAT}"

  echo "Processing: $input_file"

  # Add metadata to the audio track and overwrite the original file
  ffmpeg -i "$input_file" -map 0 -c copy -metadata:s:a:0 language=cze "$temp_file"

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$input_file"
    echo "Successfully updated: $input_file"
  else
    echo "Error updating: $input_file"
    rm -f "$temp_file" # Remove temporary file on failure
  fi
}

# Export function for use in find's -exec
export -f process_file
export VIDEO_FORMAT

# Find all video files with the specified format and process them
find "$ROOT_DIR" -type f -name "*.${VIDEO_FORMAT}" -exec bash -c 'process_file "$0"' {} \;

