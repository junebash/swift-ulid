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
