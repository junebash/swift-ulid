import Testing
import Foundation
@testable import ULID

@Suite("ULID Tests")
struct ULIDTests {
  @Test("Basic initialization")
  func basicInitialization() {
    let ulid = ULID()
    #expect(ulid.ulidString.count == 26)
  }

  @Test(
    "Initialization with date and RNG",
    arguments: (0..<100).lazy.map { _ in
      var rng = SystemRandomNumberGenerator()
      return ULID(
        date: Date(
          timeIntervalSince1970: .random(in: 0..<ULID.maxDate.timeIntervalSince1970, using: &rng)
        ),
        rng: &rng
      )
    }
  )
  func initializationWithDateAndRNG(ulid: ULID) {
    #expect(ulid.ulidString.count == 26)
  }

  @Test(
    "String round-trip",
    arguments: (0..<100).lazy.map { _ in ULID() }
  )
  func stringRoundTrip(ulid1: ULID) {
    let string = ulid1.ulidString
    let ulid2 = ULID(string)

    #expect(ulid2 != nil)
    #expect(ulid1.ulidString == ulid2?.ulidString)
    #expect(ulid1 == ulid2)
  }

  @Test("Case insensitivity")
  func caseInsensitivity() {
    let ulid = ULID()
    let uppercase = ulid.ulidString
    let lowercase = uppercase.lowercased()

    let ulid1 = ULID(uppercase)
    let ulid2 = ULID(lowercase)

    #expect(ulid1 == ulid2)
    #expect(ulid1 == ulid)
  }

  @Test(
    "Invalid string lengths",
    arguments: [
      "",
      "SHORT",
      "TOOLONGSTRINGTHATEXCEEDS26",
      "01234567890123456789012345EXTRA"
    ]
  )
  func invalidStringLengths(str: String) {
    #expect(ULID(str) == nil)
  }

  // I, L, O, U are not in Crockford's Base32
  @Test(
    "Invalid characters",
    arguments: [
      "01AN4Z07BY79KA1307SR9X4MVI",
      "01AN4Z07BY79KA1307SR9X4MVL",
      "01AN4Z07BY79KA1307SR9X4MVO",
      "01AN4Z07BY79KA1307SR9X4MVU",
      "01AN4Z07BY79KA1307SR9X4MV!"
    ]
  )
  func invalidCharacters(str: String) {
    #expect(ULID(str) == nil) // Contains I
  }

  @Test("Lexicographic sorting")
  func lexicographicSorting() {
    // Create ULIDs with different timestamps
    let date1 = Date(timeIntervalSince1970: 1_000_000)
    let date2 = Date(timeIntervalSince1970: 2_000_000)
    let date3 = Date(timeIntervalSince1970: 3_000_000)

    var rng = SystemRandomNumberGenerator()

    let ulid1 = ULID(date: date1, rng: &rng)
    let ulid2 = ULID(date: date2, rng: &rng)
    let ulid3 = ULID(date: date3, rng: &rng)

    // Verify sorting by timestamp
    #expect(ulid1 < ulid2)
    #expect(ulid2 < ulid3)
    #expect(ulid1 < ulid3)

    // Verify string sorting matches
    #expect(ulid1.ulidString < ulid2.ulidString)
    #expect(ulid2.ulidString < ulid3.ulidString)
  }

  @Test("Same millisecond sorting")
  func sameMillisecondSorting() {
    let date = Date(timeIntervalSince1970: 1_000_000)

    var rng = SystemRandomNumberGenerator()

    let ulid1 = ULID(date: date, rng: &rng)
    let ulid2 = ULID(date: date, rng: &rng)

    // Both should have same timestamp
    #expect(ulid1.timestamp == ulid2.timestamp)

    // They should be different (due to randomness)
    #expect(ulid1 != ulid2)

    // One should be less than the other (random component determines order)
    #expect((ulid1 < ulid2) || (ulid2 < ulid1))
  }

  @Test("UUID conversion")
  func uuidConversion() {
    let ulid = ULID()
    let uuid = ulid.uuid

    // UUID should have correct structure
    let uuidString = uuid.uuidString
    #expect(uuidString.count == 36) // Standard UUID format with hyphens
  }

  @Test("Timestamp extraction")
  func timestampExtraction() {
    let date = Date(timeIntervalSince1970: 1_609_459_200) // 2021-01-01 00:00:00 UTC
    var rng = SystemRandomNumberGenerator()
    let ulid = ULID(date: date, rng: &rng)

    let extractedDate = ulid.date
    let timeDifference = abs(date.timeIntervalSince1970 - extractedDate.timeIntervalSince1970)

    // Should be within 1ms (due to millisecond precision)
    #expect(timeDifference < 0.001)
  }

  @Test("Maximum timestamp")
  func maximumTimestamp() {
    // Maximum timestamp is 2^48 - 1 milliseconds
    let maxTimestampMs = UInt64(0x0000_FFFF_FFFF_FFFF)
    let maxDate = Date(timeIntervalSince1970: TimeInterval(maxTimestampMs) / 1000.0)

    var rng = SystemRandomNumberGenerator()
    let ulid = ULID(date: maxDate, rng: &rng)

    #expect(ulid.timestamp == maxTimestampMs)
  }

  @Test("Overflow timestamp clamping")
  func overflowTimestampClamping() {
    // Create a date beyond maximum timestamp
    let beyondMaxDate = Date(timeIntervalSince1970: TimeInterval(UInt64.max) / 1000.0)

    var rng = SystemRandomNumberGenerator()
    let ulid = ULID(date: beyondMaxDate, rng: &rng)

    // Should be clamped to maximum
    #expect(ulid.timestamp == 0x0000_FFFF_FFFF_FFFF)
  }

  private let validChars = Set("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

  // Generate multiple ULIDs and verify they only contain valid characters
  @Test(
    "Crockford Base32 alphabet",
    arguments: (0..<100).lazy.map { _ in ULID() }
  )
  func crockfordBase32Alphabet(ulid: ULID) {
    let string = ulid.ulidString

    for char in string {
      #expect(validChars.contains(char))
    }
  }

  @Test("Description conformance")
  func descriptionConformance() {
    let ulid = ULID()
    let description = String(describing: ulid)

    #expect(description == ulid.ulidString)
    #expect(description.count == 26)
  }

  @Test("Known value round-trip")
  func knownValueRoundTrip() {
    // Test with a known valid ULID string
    let knownString = "01ARZ3NDEKTSV4RRFFQ69G5FAV"
    let ulid = ULID(knownString)

    #expect(ulid != nil)
    #expect(ulid?.ulidString == knownString)
  }

  @Test("Zero timestamp")
  func zeroTimestamp() {
    let date = Date(timeIntervalSince1970: 0)
    var rng = SystemRandomNumberGenerator()
    let ulid = ULID(date: date, rng: &rng)

    #expect(ulid.timestamp == 0)
    #expect(ulid.date.timeIntervalSince1970 < 0.001) // Within 1ms of epoch
  }

  @Test("Binary layout size")
  func binaryLayoutSize() {
    // ULID should be exactly 16 bytes (128 bits)
    let size = MemoryLayout<ULID>.size
    #expect(size == 16)
  }

  @Test("Maximum valid ULID string")
  func maximumValidULIDString() {
    // Maximum valid ULID is 7ZZZZZZZZZZZZZZZZZZZZZZZZZ
    let maxString = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ"
    let ulid = ULID(maxString)

    #expect(ulid != nil)
  }

  // Anything starting with 8 or higher should be invalid (exceeds maximum value)
  @Test(
    "Over maximum ULID string nil",
    arguments: [
      "8ZZZZZZZZZZZZZZZZZZZZZZZZZ",
      "9ZZZZZZZZZZZZZZZZZZZZZZZZZ",
      "AZZZZZZZZZZZZZZZZZZZZZZZZZ"
    ]
  )
  func invalidStringsNil(string: String) {
    let ulid = ULID(string)
    #expect(ulid == nil, "String \(string) should be invalid")
  }

  @Test("Monotonic property within same millisecond")
  func monotonicPropertyWithinSameMillisecond() {
    // Generate many ULIDs in quick succession
    let date = Date()
    var rng = SystemRandomNumberGenerator()

    var ulids: [ULID] = []
    for _ in 0..<100 {
      ulids.append(ULID(date: date, rng: &rng))
    }

    // All should have the same timestamp
    let timestamp = ulids[0].timestamp
    for ulid in ulids {
      #expect(ulid.timestamp == timestamp)
    }

    // The strings should be sortable
    let strings = ulids.map(\.ulidString)
    let sortedStrings = strings.sorted()

    // The sorted order should match the natural ULID comparison
    let sortedULIDs = ulids.sorted()
    let sortedStringsFromULIDs = sortedULIDs.map(\.ulidString)

    #expect(sortedStrings == sortedStringsFromULIDs)
  }

  @Test("Raw component initialization")
  func rawComponentInitialization() {
    let upper: UInt64 = 0x0123456789ABCDEF
    let lower: UInt64 = 0xFEDCBA9876543210

    let ulid = ULID(upper: upper, lower: lower)

    // Verify round-trip through string
    let string = ulid.ulidString
    let ulid2 = ULID(string)

    #expect(ulid == ulid2)
  }

  @Test("All zeros")
  func allZeros() {
    let ulid = ULID(upper: 0, lower: 0)
    let string = ulid.ulidString

    // All zeros should encode to all '0' characters
    #expect(string == "00000000000000000000000000")

    // Should round-trip correctly
    let ulid2 = ULID(string)
    #expect(ulid == ulid2)
  }

  @Test("All ones in random component")
  func allOnesInRandomComponent() {
    // Maximum randomness with zero timestamp
    let ulid = ULID(upper: 0xFFFF, lower: 0xFFFF_FFFF_FFFF_FFFF)
    let string = ulid.ulidString

    // Should encode correctly
    let ulid2 = ULID(string)
    #expect(ulid == ulid2)
  }
}
