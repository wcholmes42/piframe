#!/bin/bash
# Unraid Photo Optimizer Setup Script (with Brightness Variants)

set -e

echo "================================"
echo "PiFrame Optimizer v2 Setup"
echo "================================"
echo ""

# Create directory structure
echo "[1/3] Creating directory structure..."
mkdir -p /mnt/user/Pics/Frame-Optimized/bright
mkdir -p /mnt/user/Pics/Frame-Optimized/medium
mkdir -p /mnt/user/Pics/Frame-Optimized/dim
mkdir -p /mnt/user/appdata/photo-optimizer

echo "Folder structure:"
echo "  Frame/              → Source (read-only)"
echo "  Frame-Optimized/"
echo "    ├── bright/       → 100% brightness"
echo "    ├── medium/       → 70% brightness"
echo "    └── dim/          → 40% brightness"
echo ""

# Copy optimization script
echo "[2/3] Installing optimization script..."
cat > /mnt/user/appdata/photo-optimizer/optimize.sh << 'EOF'
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
EOF
chmod +x /mnt/user/appdata/photo-optimizer/optimize.sh

# Stop existing container if present
echo "[3/3] Creating Docker container..."
docker stop photo-optimizer 2>/dev/null || true
docker rm photo-optimizer 2>/dev/null || true

# Create and start optimizer container
docker run -d \
  --name photo-optimizer \
  --restart unless-stopped \
  --entrypoint /bin/sh \
  -v /mnt/user/Pics/Frame:/source:ro \
  -v /mnt/user/Pics/Frame-Optimized:/output \
  -v /mnt/user/appdata/photo-optimizer:/scripts \
  dpokidov/imagemagick \
  -c "while true; do /scripts/optimize.sh; sleep 3600; done"

echo ""
echo "================================"
echo "Optimizer v2 Setup Complete!"
echo "================================"
echo ""
echo "Source: /mnt/user/Pics/Frame"
echo "Output: /mnt/user/Pics/Frame-Optimized/{bright,medium,dim}"
echo "Runs: Every hour + on restart"
echo ""
echo "Initial run log:"
docker logs photo-optimizer
