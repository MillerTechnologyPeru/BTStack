// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BTStack",
    products: [
        .library(
            name: "BTStack",
            targets: ["BTStack"]
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
        ),/*
        .systemLibrary(
            name: "CLibUSB",
            pkgConfig: "libusb-1.0",
            providers: [
                .aptItem(["libusb-1.0"]),
                .brewItem(["libusb"])]
        ),*/
        .testTarget(
            name: "BTStackTests",
            dependencies: ["BTStack"]
        )
    ]
)
