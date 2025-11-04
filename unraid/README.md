# Deploying PiFrame Web Server to Unraid

This moves the Flask web server from the Pi to your Unraid server, making the Pi a simple display client.

## Quick Deploy

From your Windows machine:

```bash
# 1. Copy application files to Unraid
scp -r deploy/* root@192.168.68.42:/mnt/user/appdata/piframe-web/app/

# 2. Run setup script on Unraid
ssh root@192.168.68.42 "bash /mnt/user/appdata/piframe-web/app/../setup-piframe-web.sh"

# 3. Update Pi to point to Unraid server
ssh root@192.168.68.75 "sed -i 's|http://localhost:5000|http://192.168.68.42:5000|g' /root/.xinitrc && killall -9 chromium Xorg xinit; sleep 2; startx </dev/null >/dev/null 2>&1 &"

# 4. Stop the old Flask service on the Pi
ssh root@192.168.68.75 "systemctl stop piframe-web.service && systemctl disable piframe-web.service"
```

## Architecture

**Before:**
- Pi runs Flask web server on localhost:5000
- Pi Chromium displays localhost:5000/slideshow
- Photos mounted from Unraid via CIFS

**After:**
- Unraid runs Flask web server on 192.168.68.42:5000
- Pi Chromium displays 192.168.68.42:5000/slideshow
- Flask directly accesses photos (no network mount needed)
- Pi is just a display client

## Benefits

- **Easier updates**: Update web app on Unraid without touching Pi
- **Better performance**: Unraid serves photos directly, no CIFS overhead for Flask
- **Multi-site ready**: Can host other experiments on different ports
- **Pi stays simple**: Just X + Chromium, nothing else

## Access

- **Control Panel**: http://192.168.68.42:5000
- **Slideshow**: http://192.168.68.42:5000/slideshow

## Container Details

- **Image**: piframe-web:latest (built locally)
- **Port**: 5000
- **Volumes**:
  - `/mnt/user/Pics/Frame-Optimized:/photos:ro` (read-only photos)
  - `/mnt/user/appdata/piframe-web/config:/config` (persistent config)
- **Auto-restart**: yes
