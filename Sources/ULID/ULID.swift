import Foundation

/// A Universally Unique Lexicographically Sortable Identifier (ULID).
///
/// ULIDs are 128-bit identifiers that are:
/// - Lexicographically sortable
/// - Canonically encoded as 26-character Crockford Base32 strings
/// - URL-safe
/// - Case-insensitive
/// - Monotonic sort order within the same millisecond
///
/// A ULID consists of:
/// - 48-bit timestamp (milliseconds since Unix epoch)
/// - 80-bit cryptographically secure random component
public struct ULID: Hashable, Sendable {
  // Storage: Two UInt64 values representing 128 bits
  // upper: 48-bit timestamp in high bits + 16 bits of randomness in low bits
  // lower: remaining 64 bits of randomness
  private let upper: UInt64
  private let lower: UInt64

  // MARK: - Constants

  /// Maximum valid timestamp (2^48 - 1)
  private static let maxTimestamp: UInt64 = 0x0000_FFFF_FFFF_FFFF
  private static let maxTimeInterval = TimeInterval(maxTimestamp)

  public static let maxDate = Date(timeIntervalSince1970: TimeInterval(maxTimestamp) * 0.001)

  /// Maximum valid 128-bit ULID value (7ZZZZZZZZZZZZZZZZZZZZZZZZZ)
  private static let maxValue: UInt128 =
    (UInt128(maxTimestamp) << 80) | ((1 << 80) - 1)

  /// Crockford's Base32 alphabet (excludes I, L, O, U to avoid confusion)
  private static let encodingAlphabet: [UInt8] = Array(
    "0123456789ABCDEFGHJKMNPQRSTVWXYZ".utf8
  )

  /// Decoding table: maps ASCII byte value to Base32 digit value.
  /// Invalid entries are 0xFF.
  private static let decodingTable: [UInt8] = {
    var table = [UInt8](repeating: 0xFF, count: 128)
    for (index, byte) in encodingAlphabet.enumerated() {
      table[Int(byte)] = UInt8(index)
      // Also support lowercase
      if byte >= UInt8(ascii: "A"), byte <= UInt8(ascii: "Z") {
        table[Int(byte + 32)] = UInt8(index)
      }
    }
    return table
  }()

  // MARK: - Initializers

  /// Creates a ULID with the specified date and random number generator.
  ///
  /// - Parameters:
  ///   - date: The timestamp to use for this ULID.
  ///   - rng: A random number generator to use for the random component.
  public init(date: Date, rng: inout some RandomNumberGenerator) {
    let timeInterval = date.timeIntervalSince1970 * 1000
    let timestamp: UInt64
    if timeInterval <= 0 {
      timestamp = 0
    } else if timeInterval >= Self.maxTimeInterval {
      timestamp = Self.maxTimestamp
    } else {
      timestamp = UInt64(timeInterval)
    }

    let randomHi = rng.next()
    let randomLo = rng.next()

    // upper = [48-bit timestamp][16-bit random]
    // lower = [64-bit random]
    self.upper = (timestamp << 16) | (randomHi & 0xFFFF)
    self.lower = randomLo
  }

  /// Creates a ULID with the specified date and system random number generator.
  ///
  /// - Parameter date: The timestamp to use for this ULID. Defaults to the current date.
  public init(date: Date = .now) {
    var rng = SystemRandomNumberGenerator()
    self.init(date: date, rng: &rng)
  }

  /// Creates a ULID from its raw 128-bit representation.
  ///
  /// - Parameters:
  ///   - upper: The upper 64 bits (timestamp + first 16 bits of randomness).
  ///   - lower: The lower 64 bits (remaining randomness).
  public init(upper: UInt64, lower: UInt64) {
    self.upper = upper
    self.lower = lower
  }

  /// Creates a ULID from a 26-character Crockford Base32 string.
  ///
  /// Returns `nil` if the string is not exactly 26 characters, contains
  /// invalid characters, or decodes to a value exceeding the maximum ULID.
  public init?(_ string: String) {
    guard string.count == 26 else { return nil }

    var value: UInt128 = 0

    for byte in string.utf8 {
      guard byte < 128 else { return nil }
      let digit = Self.decodingTable[Int(byte)]
      guard digit != 0xFF else { return nil }

      // Overflow check: value * 32 + digit must not exceed maxValue
      let maxAllowed = (Self.maxValue &- UInt128(digit)) / 32
      guard value <= maxAllowed else { return nil }

      value = value &* 32 &+ UInt128(digit)
    }

    self.upper = UInt64(value >> 64)
    self.lower = UInt64(truncatingIfNeeded: value)
  }

  // MARK: - Properties

  /// The 48-bit timestamp component (milliseconds since Unix epoch).
  public var timestamp: UInt64 {
    upper >> 16
  }

  /// The date represented by this ULID's timestamp.
  public var date: Date {
    Date(timeIntervalSince1970: TimeInterval(timestamp) * 0.001)
  }

  /// The canonical 26-character Crockford Base32 string representation.
  public var ulidString: String {
    let value = (UInt128(upper) << 64) | UInt128(lower)

    // Each character is 5 bits. 26 chars * 5 bits = 130 bits, but the top 2
    // bits are always 0 for valid ULIDs.
    return String(unsafeUninitializedCapacity: 26) { buffer in
      var remaining = value
      for i in stride(from: 25, through: 0, by: -1) {
        buffer.initializeElement(at: i, to: Self.encodingAlphabet[Int(remaining & 0x1F)])
        remaining >>= 5
      }
      return 26
    }
  }

  /// Converts this ULID to a UUID.
  ///
  /// The 128-bit ULID value is directly mapped to a UUID's 128-bit
  /// representation in network byte order.
  public var uuid: UUID {
    let upperBE = upper.bigEndian
    let lowerBE = lower.bigEndian
    return withUnsafeBytes(of: upperBE) { hi in
      withUnsafeBytes(of: lowerBE) { lo in
        UUID(uuid: (
          hi[0], hi[1], hi[2], hi[3], hi[4], hi[5], hi[6], hi[7],
          lo[0], lo[1], lo[2], lo[3], lo[4], lo[5], lo[6], lo[7]
        ))
      }
    }
  }
}

// MARK: - Comparable

extension ULID: Comparable {
  public static func < (lhs: ULID, rhs: ULID) -> Bool {
    (lhs.upper, lhs.lower) < (rhs.upper, rhs.lower)
  }
}

// MARK: - CustomStringConvertible

extension ULID: CustomStringConvertible {
  public var description: String {
    ulidString
  }
}
