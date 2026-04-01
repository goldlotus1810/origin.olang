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

## Parasitic Kernel Integration (BP12)

### 1. Camera → P_weight (via V4L2)

```
Syscalls (all via __syscall in Olang):
fd = open("/dev/video0", O_RDWR)                         // syscall 2
ioctl(fd, VIDIOC_S_FMT, &fmt)                            // syscall 16
ioctl(fd, VIDIOC_REQBUFS, &req)
buf_ptr = mmap(NULL, buf.length, PROT_RW, MAP_SHARED, fd, buf.m.offset)
ioctl(fd, VIDIOC_STREAMON, &type)
ioctl(fd, VIDIOC_DQBUF, &buf)  // dequeue frame
// Process frame pixels at buf_ptr
ioctl(fd, VIDIOC_QBUF, &buf)   // return buffer

Frame → mol:
S = edge_density (Sobel filter on pixel grid)
R = symmetry (compare left/right halves)
V = warmth (sum red pixels / sum blue pixels)
A = saturation (max(RGB) - min(RGB) per pixel, average)
T = motion (pixel diff between frames)
```

### 2. Screen → P_weight (via framebuffer)

```
fd = open("/dev/fb0", O_RDONLY)
ioctl(fd, 0x4600, &var_info)  // FBIOGET_VSCREENINFO
ioctl(fd, 0x4602, &fix_info)  // FBIOGET_FSCREENINFO  
fb = mmap(NULL, fix_info.smem_len, PROT_READ, MAP_SHARED, fd, 0)

// Read what's on screen — Nox sees its own output and other programs
// Same encoding as camera: edge density, color, motion
```

### 3. Keyboard → P_weight (via evdev)

```
fd = open("/dev/input/event0", O_RDONLY)
read(fd, &ev, 24)  // input_event struct

Key → mol:
S = key_category (letter=1, number=2, symbol=3, modifier=4, function=5)
R = key_position (row on keyboard, 0-3)
V = sentiment_bias (exclamation=high, question=mid, period=low)
A = typing_speed (time between keypresses)
T = sequence_position (first key in burst vs continuation)
```

### 4. Interoception → P_weight (via /proc)

```
Already available via __file_read:
/proc/loadavg → cpu load
/proc/meminfo → memory usage
/proc/self/status → Nox's own memory/threads
__heap_used() → Nox's heap state

System → mol:
S = 0 (no shape for internal state)
R = process_count / 256 (how busy)
V = 1 - error_rate (health)
A = cpu_load (activity)
T = uptime_bucket (time phase)

Homeostatic drive (Kelkar 2021):
drive(var) = |current - setpoint| / tolerance
drive > 1.0 → prioritize restoring that variable
Highest drive wins attention (hunger vs thirst analogy)
```

### 5. Audio → P_weight (future, needs ALSA)

```
fd = open("/dev/snd/pcmC0D0c", O_RDONLY)  // or ALSA via ioctl

Audio → mol:
S = 1 - stability (spectral flux)
R = stability (spectral centroid consistency)
V = zcr × 0.6 + rms × 0.4 (zero-crossing + volume)
A = rms (volume/energy)
T = zcr (pitch indicator)
```

---

## Related Specs
- [BP2 Encode](SPEC_BP2_ENCODE.md) — camera/audio encode to P_weight
- [BP5 Pipeline](SPEC_BP5_PIPELINE_EN.md) — multimodal input
- [BP9 Agent](SPEC_BP9_AGENT.md) — interoception drives homeostasis
- [VM Spec §37](VM_SPEC_COMPLETE.md) — multi-modal capture
- [SPEC_E Organism §E1](../docs/SPEC_E_ORGANISM.md) — capture design
