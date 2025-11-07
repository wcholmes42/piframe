# PiFrame Power Schedule

The PiFrame uses automated power scheduling via cron and a smart switch to turn off overnight.

## Schedule

**7:30 PM** - Pi graceful shutdown (cron)
- Cron job runs: `shutdown -h now`
- Pi shuts down gracefully (flushes writes, stops services)
- Monitor stays on (still has power)

**7:35 PM** - Smart switch cuts power (home automation)
- 5-minute delay ensures Pi is fully shut down
- Cuts power to entire power strip (Pi + Monitor)
- Safe because Pi is already off

**8:00 AM** - Smart switch restores power (home automation)
- Power restored to Pi + Monitor
- Pi automatically boots (default Raspberry Pi behavior)
- Auto-login as root (configured in systemd)
- startx launches via .xinitrc
- Chromium loads slideshow from Unraid
- Slideshow appears on screen

## Configuration

### Pi Cron Job (already configured)
```bash
# Shutdown at 7:30 PM for smart switch power-off
30 19 * * * /sbin/shutdown -h now
```

View/edit with: `ssh root@192.168.68.75 "crontab -e"`

### Smart Switch (configure in your home automation)
- **OFF**: 7:35 PM (5 minutes after Pi shutdown)
- **ON**: 8:00 AM

## Testing

**Test shutdown:**
```bash
ssh root@192.168.68.75 "shutdown -h now"
```
Wait for Pi to shut down, then flip smart switch on manually to test auto-start.

**Verify auto-start chain:**
1. Smart switch turns on
2. Pi boots (~30 seconds)
3. Root auto-login
4. X server starts (~5 seconds)
5. Chromium launches with slideshow (~5 seconds)
6. Total: ~40-45 seconds from power-on to slideshow

## Benefits

- **Graceful shutdown**: No SD card corruption risk
- **Energy savings**: Monitor + Pi off overnight
- **Fully automatic**: No manual intervention needed
- **Safe**: 5-minute buffer ensures Pi is shut down before power cut
