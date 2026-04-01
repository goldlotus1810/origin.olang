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

## Research Insights

### Interoception as Arousal/Valence (Chung et al. 2023)
```
cpu_arousal  = clamp(load_1min / num_cores × 65535, 0, 65535)
mem_pressure = clamp(mem_used / mem_total × 65535, 0, 65535)
arousal = (cpu × 4 + mem × 3 + load_trend × 3) / 10

valence = 65535 - error_rate × 65535  // high=good, low=bad
```

### Homeostatic Drive (Kelkar 2021)
```
drive(variable) = |current - setpoint| / tolerance
drive > 1.0 → prioritize restoring that variable
Highest drive wins attention (like hunger vs thirst)
```

| Variable | Sensor | Setpoint | Tolerance | Maps to |
|----------|--------|----------|-----------|---------|
| CPU load | /proc/loadavg | 0.5×cores | ±0.3×cores | A |
| Memory | /proc/meminfo | 60% | ±20% | A |
| Errors | internal | 0/min | 0-5/min | V |
| Latency | timer | target_ms | ±50% | A |

Signal MUST change behavior to qualify as interoception (Damasio).

## References
```
SPEC_E_ORGANISM.md §E1
SPEC_G_COMPLETE.md §G15
VM_SPEC_COMPLETE.md §37 (Multi-Modal Capture)
Chung et al. (2023): Life-Inspired Interoceptive AI
Kelkar (2021): Cognitive Homeostatic Agents
docs/reference/SDF_QUILEZ_COMPLETE.md
```
