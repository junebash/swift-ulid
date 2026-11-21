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
  /// Kept in network byte order so `byteSpan` can borrow it directly.
  public let storage: [16 of UInt8]

  private var rawValue: UInt128 {
    unsafeBitCast(storage, to: UInt128.self).bigEndian
  }

  // MARK: - Constants

  /// Maximum valid timestamp (2^48 - 1)
  private static var maxTimestamp: UInt64 { 0x0000_FFFF_FFFF_FFFF }
  private static let maxTimeInterval = TimeInterval(maxTimestamp)

  public static let maxDate = Date(timeIntervalSince1970: TimeInterval(maxTimestamp) * 0.001)

  /// Crockford's Base32 alphabet (excludes I, L, O, U to avoid confusion)
  /// A literal rather than an array: constant data, so no lazy setup or bounds checks.
  private static var encodingAlphabet: StaticString {
    "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  }

  /// Decoding table: maps ASCII byte value to Base32 digit value.
  /// Invalid entries are 0xFF.
  private static let decodingTable: [UInt8] = {
    var table = [UInt8](repeating: 0xFF, count: 128)
    let alphabet = encodingAlphabet.withUTF8Buffer { Array($0) }
    for (index, byte) in alphabet.enumerated() {
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
  public init(date: Date = .now, rng: inout some RandomNumberGenerator) {
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
    self.init(
      rawValue: (UInt128(timestamp) << 80)
      | (UInt128(randomHi & 0xFFFF) << 64)
      | UInt128(randomLo)
    )
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
    self.init(rawValue: (UInt128(upper) << 64) | UInt128(lower))
  }

  public init(rawValue: UInt128) {
    self.storage = unsafeBitCast(rawValue.bigEndian, to: [16 of UInt8].self)
  }

  /// Creates a ULID from its 16 bytes in network byte order.
  public init(bytes: [16 of UInt8]) {
    self.storage = bytes
  }

  /// Creates a ULID from a 26-character Crockford Base32 string.
  ///
  /// Returns `nil` if the string is not exactly 26 characters, contains
  /// invalid characters, or decodes to a value exceeding the maximum ULID.
  public init?(_ string: String) {
    guard string.utf8.count == 26 else { return nil }

    var value: UInt128 = 0
    var invalidBits: UInt8 = 0

    for byte in string.utf8 {
      let digit = Self.decodingTable[Int(byte & 0x7F)]
      invalidBits |= (byte | digit) & 0x80
      value = value &<< 5 | UInt128(digit & 0x1F)
    }

    // 26 digits hold 130 bits, so only the first digit can overflow 128.
    let firstDigit = Self.decodingTable[Int(string.utf8.first.unsafelyUnwrapped & 0x7F)]
    guard invalidBits == 0, firstDigit <= 7 else { return nil }

    self.init(rawValue: value)
  }

  // MARK: - Properties

  /// The 48-bit timestamp component (milliseconds since Unix epoch).
  public var timestamp: UInt64 {
    UInt64(rawValue >> 80)
  }

  /// The date represented by this ULID's timestamp.
  public var date: Date {
    Date(timeIntervalSince1970: TimeInterval(timestamp) * 0.001)
  }

  /// The canonical 26-character Crockford Base32 string representation.
  public var ulidString: String {
    // Each character is 5 bits. 26 chars * 5 bits = 130 bits, but the top 2
    // bits are always 0 for valid ULIDs.
    let alphabet = Self.encodingAlphabet.utf8Start
    return String(unsafeUninitializedCapacity: 26) { buffer in
      var remaining = rawValue
      for i in stride(from: 25, through: 0, by: -1) {
        buffer.initializeElement(at: i, to: alphabet[Int(remaining & 0x1F)])
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
    UUID(uuid: unsafeBitCast(storage, to: uuid_t.self))
  }

  /// The 16 bytes of this ULID in network byte order, without copying.
  public var bytes: RawSpan {
    @_lifetime(borrow self)
    borrowing get {
      storage.span.bytes
    }
  }
}

// MARK: - Equatable & Hashable

extension ULID {
  public static func == (lhs: ULID, rhs: ULID) -> Bool {
    lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

// MARK: - Comparable

extension ULID: Comparable {
  public static func < (lhs: ULID, rhs: ULID) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Codable

extension ULID: Codable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    guard let ulid = ULID(string) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ULID string: \(string)"
      )
    }
    self = ulid
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(ulidString)
  }
}

// MARK: - CustomStringConvertible

extension ULID: CustomStringConvertible {
  public var description: String {
    ulidString
  }
}
