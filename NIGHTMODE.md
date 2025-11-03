# Nightmode / Blackout Feature

The PiFrame includes an automatic nightmode feature that displays a black screen during specified hours.

## How It Works

Nightmode uses a simple trigger file mechanism:
- **Trigger file:** `/tmp/nightmode`
- When this file exists, the display shows a blank black screen
- When the file doesn't exist, the slideshow runs normally

The `.xinitrc` script checks for this file on startup and launches Chromium with either:
- Slideshow: `http://localhost:5000/slideshow`
- Black screen: `data:text/html,<body style="margin:0;background:#000"></body>`

## Schedule

By default, nightmode activates at 8 PM and deactivates at 8 AM:

```bash
# Night mode at 8pm - activate blackout
0 20 * * * touch /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx >/dev/null 2>&1 &

# Day mode at 8am - resume slideshow
0 8 * * * rm -f /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx >/dev/null 2>&1 &
```

## Manual Control

You can manually activate or deactivate nightmode:

### Activate nightmode (show black screen):
```bash
ssh root@192.168.68.75 "touch /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx &"
```

### Deactivate nightmode (resume slideshow):
```bash
ssh root@192.168.68.75 "rm -f /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx &"
```

## Changing the Schedule

To modify the nightmode hours, edit the crontab on the Pi:

```bash
ssh root@192.168.68.75
crontab -e
```

Change the hours in the cron expressions (format: `minute hour * * *`)

For example, to activate at 10 PM and deactivate at 6 AM:
```bash
# Night mode at 10pm
0 22 * * * touch /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx >/dev/null 2>&1 &

# Day mode at 6am
0 6 * * * rm -f /tmp/nightmode; killall -9 chromium xinit Xorg 2>/dev/null; sleep 2; DISPLAY=:0 startx >/dev/null 2>&1 &
```
