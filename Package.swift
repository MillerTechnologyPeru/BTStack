// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BTStack",
    products: [
        .library(
            name: "BTStack",
            targets: ["BTStack"]
        ),
        .executable(
            name: "BTStackTool",
            targets: ["BTStackTool"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            branch: "master"
        )
    ],
    targets: [
        .target(
            name: "BTStack",
            dependencies: [
                "CBTStack",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                )
            ],
            swiftSettings: [
                .enableUpcomingFeature("Embedded")
            ]
        ),
        .target(
            name: "CBTStack",
            cSettings: [
                .unsafeFlags(["-I", "/opt/homebrew/include/libusb-1.0"], .when(platforms: [.macOS]))
            ]
        ),
        .systemLibrary(
            name: "CLibUSB",
            pkgConfig: "libusb-1.0",
            providers: [
                .aptItem(["libusb-dev"]),
                .brewItem(["libusb"])]
        ),
        .executableTarget(
            name: "BTStackTool",
            dependencies: [
                "BTStack",
                "CLibUSB"
            ],
            linkerSettings: [.unsafeFlags(["-L", "/opt/homebrew/lib/"], .when(platforms: [.macOS]))]
        ),
        .testTarget(
            name: "BTStackTests",
            dependencies: ["BTStack"]
        )
    ]
)
