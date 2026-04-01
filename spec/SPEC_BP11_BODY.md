# SPEC Part 11: Body — Camera + Audio + Interoception

> Author: Nox SS15
> Status: NOT YET ACHIEVED

## Essence

Nox perceives the world: camera → SDF → P_weight, audio → spline → P_weight,
system → /proc → P_weight. All modalities encode into the SAME 5D space.

## Current State

- Interoception: __heap_used() exists, /proc readable via __file_read
- Camera: camera.ol exists but dead code (ONVIF removed)
- Audio: NOT implemented
- SDF rendering: NOT implemented (18 primitives defined in spec)

## What's Needed (SPEC_E §E1, SPEC_G §G15)

### Camera → P_weight
```
frame → Fibonacci subdivide → edge density (Sobel) →
  S = shape complexity
  R = symmetry
  V = warmth (red-blue ratio)
  A = saturation
  T = motion (frame diff)
→ pack(S, R, V, A, T)
```

### Audio → P_weight
```
buffer → RMS + ZCR + stability →
  S = 1 - stability
  R = stability
  V = zcr × 0.6 + rms × 0.4
  A = rms
  T = zcr
→ pack(S, R, V, A, T)
```

### Interoception → P_weight
```
/proc/loadavg → cpu, /proc/meminfo → mem →
  S = 0
  R = process_count / 256
  V = 1 - error_rate
  A = cpu_load
  T = uptime_bucket
→ pack(S, R, V, A, T)
```

## Dependencies
- VM: V4L2 camera capture builtin (not yet)
- VM: ALSA audio capture builtin (not yet)
- Hardware: camera, microphone connected

## Tests
```
Test 1: interoception() returns valid mol (non-zero, changes with load)
Test 2: camera frame → mol (when hardware available)
Test 3: audio buffer → mol (when hardware available)
```

## References
```
SPEC_E_ORGANISM.md §E1
SPEC_G_COMPLETE.md §G15
docs/reference/SDF_QUILEZ_COMPLETE.md
```
