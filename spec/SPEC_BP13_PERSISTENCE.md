# BP13: Persistence — Nox Survives Restart

> Nox must remember across sessions. Memory that dies on restart is not memory.

## Problem

Currently Nox loses:
- Silk weights (Hebbian connections)
- STM (short-term memory, 32 slots)
- Working Memory (4 slots)
- Activation levels
- Session context

Only KnowTree can be saved/loaded via kt_save/kt_load, but the format is slow to parse and exhausts heap at ~1500 facts.

## Solution: 3-Layer Persistence (Inspired by LTP)

### Layer 1: mmap Weights (Immediate)

Map silk weight table directly into process address space via `mmap()`.

```
File: ~/.nox/silk_weights.bin
Format: [edge_hash:4][weight:2][fire_count:2][last_fire:4] = 12 bytes/edge
Size: 64K edges × 12 bytes = 768KB
```

On startup: `mmap(silk_file, PROT_RW, MAP_SHARED)` → instant recovery.
On write: OS handles dirty page writeback automatically.
On crash: last synced state preserved (lose only in-flight writes).

**VM change**: Add `OP_MMAP_PERSIST` (0x66) — maps a file into Zone A.

### Layer 2: Write-Ahead Log (Incremental)

Every learning event appends to a WAL file:

```
File: ~/.nox/learning.wal
Record: [timestamp:4][op:1][key:4][old_value:2][new_value:2] = 13 bytes
```

Operations logged:
- SILK_FIRE (op=1): edge fired, weight changed
- SILK_DECAY (op=2): decay applied
- KT_LEARN (op=3): new fact added
- KT_PROMOTE (op=4): ĐN → QR promotion
- STM_PUSH (op=5): short-term memory entry

On startup: replay WAL entries newer than mmap snapshot.
Periodically: checkpoint (sync mmap + truncate WAL).

### Layer 3: Dream Consolidation (Biological)

During idle (>5 min no input) or Fibonacci trigger:

1. Scan WAL for frequently-fired edges (fire_count > Fib threshold)
2. Batch-write promoted QR entries to persistent KnowTree file
3. Prune decayed edges (weight < threshold) from mmap
4. Sync mmap to disk (msync)
5. Truncate WAL

This mimics brain's sleep consolidation: temporary → permanent.

## Binary Knowledge Format (replaces text parsing)

```
File: ~/.nox/knowtree.nkb (Nox Knowledge Binary)

Header (64 bytes):
  [magic:4 "NKB\0"][version:2][node_count:4][edge_count:4]
  [data_offset:4][index_offset:4][checksum:4][reserved:34]

Index (12 bytes per node):
  [mol_hash:4][data_offset:4][data_len:4]

Data (variable):
  [chain_len:2][chain_data:N][metadata:M]
```

Accessed via mmap + binary search on mol_hash. O(log n) lookup.
Demand-paged: OS loads only accessed pages.

**Heap impact**: Index only = 12 bytes × 100K nodes = 1.2MB. Data stays on disk.

## LRU Cache

In-memory cache of recently accessed nodes:

```
Cache: 2048 slots × 64 bytes = 128KB
Eviction: LRU (least recently used)
Hit: return from cache
Miss: load from mmap'd NKB file, evict LRU entry
```

## Implementation

### New VM builtins:
| Builtin | Args | Does |
|---------|------|------|
| `__persist_init` | (path) | mmap silk + WAL + NKB files |
| `__persist_sync` | () | msync + checkpoint |
| `__persist_wal_append` | (op, key, old, new) | Append WAL record |

### New Olang stdlib:
```
// stdlib/persist.ol
fn persist_init(base_path) { ... }
fn persist_learn(edge_hash, new_weight) { ... }  // fires WAL append
fn persist_consolidate() { ... }  // dream consolidation
fn persist_shutdown() { ... }  // final sync
```

### Files created:
```
~/.nox/
  silk_weights.bin    # mmap'd silk table (768KB)
  learning.wal        # write-ahead log (grows, truncated on checkpoint)
  knowtree.nkb        # binary knowledge (mmap'd, demand-paged)
  nox.checkpoint      # last checkpoint timestamp
```

## Test Plan
1. Learn 100 facts → restart → verify all 100 present
2. Fire silk edges → restart → verify weights preserved
3. Kill -9 (crash) → restart → verify WAL replay recovers
4. Load 10K facts → verify heap stays under 2MB (only cache in memory)
5. Benchmark: startup time < 100ms (mmap, no parsing)

## Tổng hợp tiếng Việt

BP13 giải quyết vấn đề "Nox quên mỗi khi restart":
- **mmap**: Map file trực tiếp vào bộ nhớ. Ghi vào bộ nhớ = ghi vào file tự động.
- **WAL**: Mỗi lần học, ghi log. Crash → replay log → phục hồi.
- **Dream consolidation**: Giống não ngủ — tạm thời → vĩnh viễn theo chu kỳ.
- **Binary knowledge**: Không parse text. Binary search + demand paging. 100K facts, heap chỉ dùng 1.2MB.
