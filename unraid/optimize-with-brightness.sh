#!/bin/bash
# Photo Optimizer with Brightness Variants
SOURCE="/source"
OUTPUT="/output"

echo "Starting optimization with brightness variants at $(date)"

# Process all photos
for img in "$SOURCE"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    if [ -f "$img" ]; then
        filename=$(basename "$img")
        base="${filename%.*}"
        ext="${filename##*.}"

        # Skip if all variants already exist
        if [ -f "$OUTPUT/bright/$filename" ] && \
           [ -f "$OUTPUT/medium/$filename" ] && \
           [ -f "$OUTPUT/dim/$filename" ]; then
            continue
        fi

        echo "Processing: $filename"

        # Create base optimized image (1920x1080)
        temp_file="/tmp/${filename}"
        convert "$img" -resize 1920x1080^ -gravity center -extent 1920x1080 "$temp_file"

        # Generate brightness variants
        # 100% - bright (full brightness)
        cp "$temp_file" "$OUTPUT/bright/$filename"
        echo "  → bright (100%)"

        # 70% - medium
        convert "$temp_file" -modulate 70,100,100 "$OUTPUT/medium/$filename"
        echo "  → medium (70%)"

        # 40% - dim
        convert "$temp_file" -modulate 40,100,100 "$OUTPUT/dim/$filename"
        echo "  → dim (40%)"

        rm "$temp_file"
    fi
done

echo "Optimization complete at $(date)"
echo "Total photos: $(ls -1 "$OUTPUT/bright" 2>/dev/null | wc -l)"
