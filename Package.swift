// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-ulid",
  platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .visionOS(.v26)],
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
      name: "ULID",
      swiftSettings: [
        .enableExperimentalFeature("Lifetimes"),
      ]
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
