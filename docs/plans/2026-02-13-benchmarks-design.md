# ULID Benchmarks Design

## Tool

ordo-one's `package-benchmark` v1.x -- Swift.org endorsed, release mode by default, rich metrics (wall clock, CPU, memory, ARC, syscalls).

## Directory Structure

```
swift-ulid/
├── Benchmarks/
│   └── ULIDBenchmarks/
│       └── ULIDBenchmarks.swift
├── Package.swift  (updated with benchmark target)
└── ...existing files...
```

## Benchmark Cases

Side-by-side ULID vs Foundation.UUID where applicable:

| Operation | ULID | UUID |
|-----------|------|------|
| Random generation | `ULID()` | `UUID()` |
| Deterministic creation | `ULID(date:rng:)` with seeded RNG | `UUID(uuid:)` with fixed bytes |
| String parsing | `ULID(ulidString)` | `UUID(uuidString:)` |
| String serialization | `.ulidString` | `.uuidString` |
| Comparison/sorting | `<` on two values | ULID-only (UUID isn't Comparable) |
| UUID conversion | `.uuid` | N/A |
| Timestamp extraction | `.date` | ULID-only (UUIDs don't encode timestamps) |

## Implementation Details

- Each benchmark uses `scaledIterations` and `blackHole()` for reliable measurements.
- Metrics: default set (wall clock, CPU, memory, throughput).
- Run via: `swift package benchmark`
- Deterministic benchmarks use a seeded RNG to ensure reproducibility without affecting measurement.
