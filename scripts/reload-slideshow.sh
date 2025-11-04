#!/bin/bash
killall -9 chromium Xorg xinit 2>/dev/null
sleep 2
startx </dev/null >/dev/null 2>&1 &
