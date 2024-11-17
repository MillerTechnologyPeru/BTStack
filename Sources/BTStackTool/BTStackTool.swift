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
    
    static func main() {
        
        btstack_memory_init()
                
        btstack_run_loop_init(btstack_run_loop_posix_get_instance())
        defer {
            btstack_run_loop_deinit()
        }
        
        Thread.detachNewThread {
            do {
                try start()
            }
            catch {
                print("Error \(error)")
                exit(EXIT_FAILURE)
            }
        }
        
        btstack_run_loop_execute()
    }
    
    static func start() throws(BTStackError) {
        
        let hostController = HostController.default
        hostController.log = { print("HCI:", $0) }
        try hostController.setPower(.on)
        
        // wait for Bluetooth to turn on
        while hostController.state != .on {
            Thread.sleep(forTimeInterval: 1.0)
        }
                
        hostController.setAdvertisementParameters()
        
        // Estimote iBeacon B9407F30-F5F8-466E-AFF9-25556B57FE6D
        // Major 0x01 Minor 0x01
        let uuid = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!
        let beacon = AppleBeacon(uuid: uuid, major: 0x01, minor: 0x01, rssi: -10)
        let flags: GAPFlags = [.lowEnergyGeneralDiscoverableMode, .notSupportedBREDR]
        hostController.advertisement = .init(beacon: beacon, flags: flags)

        // scan response with name and bluetooth address
        let address = hostController.address
        let name = GAPCompleteLocalName(name: "BTStack " + address.description)
        let scanResponse: LowEnergyAdvertisingData = GAPDataEncoder.encode(name)
        hostController.scanResponse = scanResponse
        hostController.isAdvertising = true
        
        print("Advertisment Name:", name.description)
        
        let l2cap = L2CAP.shared
        l2cap.log = { print("L2CAP:", $0) }
        l2cap.register(channel: 0x0004) // ATT
        
        
        while true {
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
}
