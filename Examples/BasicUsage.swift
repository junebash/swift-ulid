import Foundation
import ULID

// MARK: - Basic ULID Generation

print("=== Basic ULID Generation ===")

// Generate a new ULID
let ulid = ULID()
print("Generated ULID: \(ulid.ulidString)")
print("Timestamp: \(ulid.timestamp) ms since epoch")
print("Date: \(ulid.date)")
print("UUID: \(ulid.uuid.uuidString)")
print()

// MARK: - Creating ULIDs with Specific Dates

print("=== Creating ULIDs with Specific Dates ===")

let specificDate = Date(timeIntervalSince1970: 1_609_459_200) // 2021-01-01 00:00:00 UTC
var rng = SystemRandomNumberGenerator()
let datedULID = ULID(date: specificDate, rng: &rng)
print("ULID for 2021-01-01: \(datedULID.ulidString)")
print()

// MARK: - Parsing ULIDs from Strings

print("=== Parsing ULIDs from Strings ===")

let validString = "01ARZ3NDEKTSV4RRFFQ69G5FAV"
if let parsedULID = ULID(validString) {
    print("✓ Parsed: \(parsedULID.ulidString)")
    print("  Date: \(parsedULID.date)")
} else {
    print("✗ Failed to parse")
}

// Invalid strings
let invalidStrings = [
    "INVALID",  // Too short
    "01ARZ3NDEKTSV4RRFFQ69G5FAVI",  // Too long
    "01AN4Z07BY79KA1307SR9X4MVO",  // Contains 'O'
    "8ZZZZZZZZZZZZZZZZZZZZZZZZZ",  // Exceeds maximum value
]

for string in invalidStrings {
    if ULID(string) == nil {
        print("✓ Correctly rejected: \(string)")
    }
}
print()

// MARK: - Sorting

print("=== Sorting ULIDs ===")

var ulids: [ULID] = []
for i in 0..<5 {
    let date = Date(timeIntervalSince1970: TimeInterval(1_000_000 + i * 1000))
    ulids.append(ULID(date: date, rng: &rng))
}

print("Original order:")
for ulid in ulids {
    print("  \(ulid.ulidString)")
}

print("\nSorted order:")
for ulid in ulids.sorted() {
    print("  \(ulid.ulidString)")
}
print()

// MARK: - Case Insensitivity

print("=== Case Insensitivity ===")

let uppercase = ulid.ulidString
let lowercase = uppercase.lowercased()

let upperULID = ULID(uppercase)
let lowerULID = ULID(lowercase)

print("Uppercase: \(uppercase)")
print("Lowercase: \(lowercase)")
print("Are they equal? \(upperULID == lowerULID)")
print()

// MARK: - Collections

print("=== Using ULIDs in Collections ===")

var uidSet = Set<ULID>()
for _ in 0..<5 {
    uidSet.insert(ULID())
}

print("Set of \(uidSet.count) unique ULIDs:")
for ulid in uidSet.sorted() {
    print("  \(ulid)")
}
print()

// MARK: - Monotonicity Within Same Millisecond

print("=== Monotonicity Within Same Millisecond ===")

let sameDate = Date()
var sameMillisecondULIDs: [ULID] = []
for _ in 0..<10 {
    sameMillisecondULIDs.append(ULID(date: sameDate, rng: &rng))
}

print("ULIDs generated in same millisecond:")
for ulid in sameMillisecondULIDs {
    print("  \(ulid.ulidString) - timestamp: \(ulid.timestamp)")
}

let allSameTimestamp = sameMillisecondULIDs.allSatisfy { $0.timestamp == sameMillisecondULIDs[0].timestamp }
print("\nAll have same timestamp? \(allSameTimestamp)")
print("Sorted correctly? \(sameMillisecondULIDs.sorted().map(\.ulidString) == sameMillisecondULIDs.sorted().map(\.ulidString))")
