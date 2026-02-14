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
    let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") ?? UUID()
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
