# Brightness Level Selection

## Human Perception

**Just Noticeable Difference (JND):**
- Ideal conditions: ~1% brightness change detectable
- Practical viewing: 5-10% change noticeable
- Comfortable transition: 15-30% steps

## Recommended Levels

### 3 Levels (Current Implementation)
**Best for: Simple time-based switching**

- **bright** (100%) - Full brightness, daytime
- **medium** (70%) - Comfortable evening brightness
- **dim** (40%) - Night mode, minimal eye strain

**Advantages:**
- Simple, obvious differences
- Storage efficient (3x source size)
- Clear use cases per time of day
- 30% steps = comfortable, not jarring

**Time mapping suggestion:**
- 8am-5pm: bright
- 5pm-7pm: medium
- 7pm-shutdown: dim

---

### 5 Levels (Alternative - More Granular)
**Best for: Gradual transitions, sensor-based dimming**

- **100%** - Full bright (morning/midday)
- **80%** - Slightly dimmed (afternoon)
- **60%** - Medium (early evening)
- **40%** - Dim (evening)
- **20%** - Very dim (night/ambient)

**Advantages:**
- Smoother transitions
- More precise control
- Better for ambient light sensor integration

**Disadvantages:**
- 5x storage overhead
- More complex scheduling
- Smaller differences harder to notice

---

### 7+ Levels (Not Recommended)
**Why avoid:**
- Diminishing returns - hard to notice 10% steps
- Storage waste (7x+ source size)
- Overcomplicated scheduling
- Unnecessary for time-based switching

## Implementation Details

### ImageMagick `-modulate` Command
```bash
convert input.jpg -modulate BRIGHTNESS,100,100 output.jpg
```
- First value: brightness (0-200, 100=original)
- Second: saturation (keep at 100)
- Third: hue (keep at 100)

**Current levels:**
- bright: 100 (no change)
- medium: 70 (30% darker)
- dim: 40 (60% darker)

### Storage Impact
For 1000 photos @ 1920x1080 (~500KB each):
- Source: ~500MB
- 3 levels: ~1.5GB
- 5 levels: ~2.5GB
- 10 levels: ~5GB

## Testing Recommendations

If unsure about 3 vs 5 levels:
1. Generate 5 levels initially
2. View at different times of day
3. See if 80%/60% distinction matters
4. Drop to 3 if 60%/70%/80% feel redundant

Most users find **3 levels sufficient** for time-based dimming.
