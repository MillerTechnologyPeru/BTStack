//
//  BTStackTool.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import Foundation
import Bluetooth
import BluetoothGAP
import BTStack
import CBTStack

@main
struct BTStackTool {
    
    static func main() throws {
        
        btstack_run_loop_init(btstack_run_loop_posix_get_instance())
        defer {
            btstack_run_loop_deinit()
        }
                
        start()
        
        while true {
            btstack_run_loop_execute()
        }
    }
    
    static func start() {
        
        let hostController = HostController.default
        
        hostController.setPower(.on)
        
        // wait for Bluetooth to turn on
        while hostController.state != .on {
            Thread.sleep(forTimeInterval: 1.0)
        }
                
        var address: BluetoothAddress = .zero
        hostController.setAdvertisementParameters(directAddress: &address)
        
        // Estimote iBeacon B9407F30-F5F8-466E-AFF9-25556B57FE6D
        // Major 0x01 Minor 0x01
        let uuid = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let beacon = AppleBeacon(uuid: uuid, major: 0x01, minor: 0x01, rssi: -10)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        hostController.advertisement = .init(beacon: beacon, flags: flags)

        // scan response with name and bluetooth address
        let name = GAPCompleteLocalName(name: "BTStack " + address.description)
        let scanResponse: LowEnergyAdvertisingData = GAPDataEncoder.encode(name)
        hostController.scanResponse = scanResponse
        hostController.isAdvertising = true
        
        print("Advertisment Name: ", name.description)
    }
}
