#!/bin/bash
# Unraid Photo Optimizer Setup Script

set -e

echo "================================"
echo "PiFrame Optimizer Setup (Unraid)"
echo "================================"
echo ""

# Create directories
echo "[1/3] Creating directories..."
mkdir -p /mnt/user/Pics/Frame-Optimized
mkdir -p /mnt/user/appdata/photo-optimizer

# Download optimization script
echo "[2/3] Creating optimization script..."
cat > /mnt/user/appdata/photo-optimizer/optimize.sh << 'EOF'
#!/bin/bash
SOURCE="/source"
OUTPUT="/output"

echo "Starting optimization at $(date)"

# Process all photos
for img in "$SOURCE"/*.{jpg,jpeg,png,JPG,JPEG,PNG}; do
    if [ -f "$img" ]; then
        filename=$(basename "$img")
        # Skip if already optimized
        if [ ! -f "$OUTPUT/$filename" ]; then
            convert "$img" -resize 1920x1080 -gravity center -background black -extent 1920x1080 "$OUTPUT/$filename"
            echo "Optimized: $filename"
        fi
    fi
done

echo "Optimization complete at $(date)"
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
echo "Optimizer Setup Complete!"
echo "================================"
echo ""
echo "Source: /mnt/user/Pics/Frame"
echo "Output: /mnt/user/Pics/Frame-Optimized"
echo "Runs: Every hour + on restart"
echo ""
docker logs photo-optimizer
