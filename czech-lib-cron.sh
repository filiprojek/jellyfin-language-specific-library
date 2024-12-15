#!/bin/bash

# Define directories and language codes
SOURCE_DIR_MOVIES="/media/movies"
TARGET_DIR_MOVIES="/media/cz_movies"
SOURCE_DIR_SERIES="/media/series"
TARGET_DIR_SERIES="/media/cz_series"
LANGUAGES_TO_CHECK=("cze" "cz" "Czech" "czech" "česky" "cs" "ces")
FFPROBE="/usr/lib/jellyfin-ffmpeg/ffprobe"

# List of file extensions to skip
SKIP_EXTENSIONS=("nfo" "srt" "sh")

# Function to process a source directory
process_directory() {
	local SOURCE_DIR="$1"
	local TARGET_DIR="$2"
	local IS_SERIES="$3"

	# Loop through all files in SOURCE_DIR and subdirectories
	find "$SOURCE_DIR" -type f | while read FILE; do
		# Get the file extension
		EXTENSION="${FILE##*.}"

		# Check if the file extension is in the skip list
		if [[ " ${SKIP_EXTENSIONS[@]} " =~ " $EXTENSION " ]]; then
			# Skip the file if it's in the skip list
			continue
		fi

		echo "Processing $FILE"

		# Get the languages from the current file
		LANGUAGES=($($FFPROBE -v error -show_entries stream=codec_type:stream_tags=language:stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$FILE" | tr '\n' ' ' | grep -o 'audio [^ ]*' | awk '{print $2}'))

		# Check if any of the languages in LANGUAGES_TO_CHECK exist in LANGUAGES
		FOUND=false
		for LANG_TO_CHECK in "${LANGUAGES_TO_CHECK[@]}"; do
			if [[ " ${LANGUAGES[@]} " =~ " $LANG_TO_CHECK " ]]; then
				FOUND=true
				break
			fi
		done

		if $FOUND; then
			echo "Found a matching language (${LANGUAGES_TO_CHECK[@]}) in the list"
			# Determine the symlink target based on whether this is a series or a movie
			if [ "$IS_SERIES" = true ]; then
				# For series, link the <Series name> directory
				PARENT_DIR=$(dirname "$(dirname "$FILE")")
			else
				# For movies, link the <Movie name> directory
				PARENT_DIR=$(dirname "$FILE")
			fi

			# Create a symlink to the parent directory in TARGET_DIR
			ln -snf "$PARENT_DIR" "$TARGET_DIR/$(basename "$PARENT_DIR")"
			echo "Symlink \"$PARENT_DIR\" \"$TARGET_DIR/$(basename "$PARENT_DIR")\""
			echo "Symlink created for $PARENT_DIR"
		else
			echo "Skipping $FILE"
		fi

	done
}

# Process movies and series directories
process_directory "$SOURCE_DIR_MOVIES" "$TARGET_DIR_MOVIES" false
process_directory "$SOURCE_DIR_SERIES" "$TARGET_DIR_SERIES" true

