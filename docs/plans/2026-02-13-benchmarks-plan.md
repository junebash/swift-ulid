# ULID Benchmarks Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add performance benchmarks comparing ULID against Foundation.UUID using ordo-one's package-benchmark.

**Architecture:** A separate executable target under `Benchmarks/ULIDBenchmarks/` using package-benchmark. Benchmarks run in release mode by default via `swift package benchmark`. Each benchmark uses `scaledIterations` for automatic iteration scaling and `blackHole()` to prevent dead-code elimination.

**Tech Stack:** Swift 6.2, ordo-one/package-benchmark v1.x, SwiftPM

---

### Task 1: Add package-benchmark dependency and executable target to Package.swift

**Files:**
- Modify: `Package.swift`

**Step 1: Update Package.swift**

Add the package-benchmark dependency and an executable target for the benchmarks:

```swift
// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-ulid",
  platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)],
  products: [
    .library(
      name: "ULID",
      targets: ["ULID"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.4.0"),
  ],
  targets: [
    .target(
      name: "ULID"
    ),
    .testTarget(
      name: "ULIDTests",
      dependencies: ["ULID"]
    ),
    .executableTarget(
      name: "ULIDBenchmarks",
      dependencies: [
        "ULID",
        .product(name: "Benchmark", package: "package-benchmark"),
      ],
      path: "Benchmarks/ULIDBenchmarks",
      plugins: [
        .plugin(name: "BenchmarkPlugin", package: "package-benchmark"),
      ]
    ),
  ]
)
```

**Step 2: Verify the package resolves**

Run: `swift package resolve`
Expected: Dependencies resolve successfully, no errors.

**Step 3: Commit**

```
feat: add package-benchmark dependency and ULIDBenchmarks target
```

---

### Task 2: Create benchmark file with a seeded RNG helper

**Files:**
- Create: `Benchmarks/ULIDBenchmarks/ULIDBenchmarks.swift`

**Step 1: Create the benchmarks directory**

Run: `mkdir -p Benchmarks/ULIDBenchmarks`

**Step 2: Write the benchmark file with all benchmark cases**

Create `Benchmarks/ULIDBenchmarks/ULIDBenchmarks.swift` with all benchmarks. A seeded RNG is needed for deterministic benchmarks to avoid measuring RNG overhead inconsistently:

```swift
import Benchmark
import Foundation
import ULID

/// A simple seeded RNG for deterministic benchmarks.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    // xorshift64
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return state
  }
}

let benchmarks: @Sendable () -> Void = {

  // MARK: - Random Generation

  Benchmark("ULID.init() — random generation") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(ULID())
    }
  }

  Benchmark("UUID() — random generation") { benchmark in
    for _ in benchmark.scaledIterations {
      blackHole(UUID())
    }
  }

  // MARK: - Deterministic Creation

  Benchmark("ULID.init(date:rng:) — deterministic") { benchmark in
    let date = Date(timeIntervalSince1970: 1_700_000)
    for _ in benchmark.scaledIterations {
      var rng = SeededRandomNumberGenerator(seed: 42)
      blackHole(ULID(date: date, rng: &rng))
    }
  }

  Benchmark("UUID(uuid:) — deterministic") { benchmark in
    let bytes: uuid_t = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)
    for _ in benchmark.scaledIterations {
      blackHole(UUID(uuid: bytes))
    }
  }

  // MARK: - String Parsing

  Benchmark("ULID.init(string) — parsing") { benchmark in
    let string = "01ARZ3NDEKTSV4RRFFQ69G5FAV"
    for _ in benchmark.scaledIterations {
      blackHole(ULID(string))
    }
  }

  Benchmark("UUID(uuidString:) — parsing") { benchmark in
    let string = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
    for _ in benchmark.scaledIterations {
      blackHole(UUID(uuidString: string))
    }
  }

  // MARK: - String Serialization

  Benchmark("ULID.ulidString — serialization") { benchmark in
    let ulid = ULID(upper: 0x0001_8AFF_1234_5678, lower: 0xABCD_EF01_2345_6789)
    for _ in benchmark.scaledIterations {
      blackHole(ulid.ulidString)
    }
  }

  Benchmark("UUID.uuidString — serialization") { benchmark in
    let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
    for _ in benchmark.scaledIterations {
      blackHole(uuid.uuidString)
    }
  }

  // MARK: - Comparison (ULID-only, UUID isn't Comparable)

  Benchmark("ULID < ULID — comparison") { benchmark in
    let a = ULID(upper: 0x0001_8AFF_0000_0000, lower: 0x0000_0000_0000_0001)
    let b = ULID(upper: 0x0001_8AFF_0000_0000, lower: 0x0000_0000_0000_0002)
    for _ in benchmark.scaledIterations {
      blackHole(a < b)
    }
  }

  // MARK: - UUID Conversion (ULID-only)

  Benchmark("ULID.uuid — conversion to UUID") { benchmark in
    let ulid = ULID(upper: 0x0001_8AFF_1234_5678, lower: 0xABCD_EF01_2345_6789)
    for _ in benchmark.scaledIterations {
      blackHole(ulid.uuid)
    }
  }

  // MARK: - Timestamp Extraction (ULID-only)

  Benchmark("ULID.date — timestamp extraction") { benchmark in
    let ulid = ULID(upper: 0x0001_8AFF_1234_5678, lower: 0xABCD_EF01_2345_6789)
    for _ in benchmark.scaledIterations {
      blackHole(ulid.date)
    }
  }
}
```

**Step 3: Verify the benchmark target builds**

Run: `swift build --target ULIDBenchmarks -c release`
Expected: Builds successfully.

**Step 4: Run the benchmarks**

Run: `swift package benchmark`
Expected: All benchmarks run and produce output with percentile metrics.

**Step 5: Commit**

```
feat: add ULID vs UUID performance benchmarks
```

---

## Running

```bash
# Run all benchmarks
swift package benchmark

# Run specific target only
swift package benchmark --target ULIDBenchmarks
```
