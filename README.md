# swift-ulid

A pure Swift implementation of [ULID (Universally Unique Lexicographically Sortable Identifier)](https://github.com/ulid/spec).

## Overview

ULIDs are 128-bit identifiers that combine:
- **48-bit timestamp** (milliseconds since Unix epoch)
- **80-bit cryptographically secure randomness**

### Features

- ✅ Lexicographically sortable
- ✅ Canonically encoded as 26-character Crockford Base32 strings
- ✅ URL-safe and case-insensitive
- ✅ Compact 16-byte binary representation
- ✅ Monotonic sort order within the same millisecond
- ✅ Compatible with UUID

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/junebash/swift-ulid.git", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
import ULID

// Generate a new ULID
let ulid = ULID()
print(ulid.ulidString)  // e.g., "01ARZ3NDEKTSV4RRFFQ69G5FAV"

// Create from a specific date
let date = Date()
var rng = SystemRandomNumberGenerator()
let ulid = ULID(date: date, rng: &rng)

// Parse from string
if let ulid = ULID("01ARZ3NDEKTSV4RRFFQ69G5FAV") {
    print(ulid.timestamp)  // Get the timestamp in milliseconds
    print(ulid.date)       // Get the Date
    print(ulid.uuid)       // Convert to UUID
}
```

### Sorting

ULIDs are naturally sorted by their timestamp, then by their random component:

```swift
let ulid1 = ULID(date: Date(timeIntervalSince1970: 1_000_000), rng: &rng)
let ulid2 = ULID(date: Date(timeIntervalSince1970: 2_000_000), rng: &rng)

print(ulid1 < ulid2)  // true

// String sorting matches ULID sorting
print(ulid1.ulidString < ulid2.ulidString)  // true
```

### Properties

```swift
let ulid = ULID()

// Get the canonical string representation
let string = ulid.ulidString  // 26 characters

// Get the timestamp (milliseconds since Unix epoch)
let timestamp = ulid.timestamp  // UInt64

// Get the date
let date = ulid.date  // Date

// Convert to UUID
let uuid = ulid.uuid  // UUID
```

## Specification Compliance

This implementation follows the [ULID specification](https://github.com/ulid/spec):

- **Crockford's Base32**: Uses alphabet `0123456789ABCDEFGHJKMNPQRSTVWXYZ` (excludes I, L, O, U)
- **Case insensitive**: Accepts both uppercase and lowercase input
- **Maximum value**: `7ZZZZZZZZZZZZZZZZZZZZZZZZZ` (timestamp = 2^48-1)
- **Binary layout**: 16 bytes (128 bits) in network byte order
- **Overflow protection**: Invalid strings are rejected during parsing

## Performance

- **Size**: Exactly 16 bytes (2 × UInt64)
- **Encoding/Decoding**: Optimized Base32 implementation with overflow detection
- **Sorting**: O(1) comparison using native integer comparison

## Testing

```bash
swift test
```

The library includes comprehensive tests covering:
- String encoding/decoding round-trips
- Lexicographic sorting
- Edge cases (maximum values, overflow, invalid inputs)
- Crockford Base32 alphabet validation
- UUID conversion
- Timestamp extraction

## License

MIT
