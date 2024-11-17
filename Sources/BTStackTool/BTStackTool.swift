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
    
    nonisolated(unsafe) static let hostController = HostController.default
    
    nonisolated(unsafe) static let l2cap = L2CAP.shared
    
    static let peripheral = BTStackPeripheral(hostController: hostController)
    
    static func main() {
        
        btstack_memory_init()
                
        btstack_run_loop_init(btstack_run_loop_posix_get_instance())
        defer {
            btstack_run_loop_deinit()
        }
        
        hostController.log = { print("HCI:", $0) }
        l2cap.log = { print("L2CAP:", $0) }
        peripheral.log = { print("Peripheral:", $0) }
        
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
    
    static func start() throws(BTStackPeripheral.Error) {
        
        let hostController = HostController.default
        do {
            try hostController.setPower(.on)
        }
        catch {
            throw .library(error)
        }
        
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
        let advertisement = LowEnergyAdvertisingData(
            beacon: beacon,
            flags: flags
        )
        
        // scan response with name and bluetooth address
        let address = hostController.address
        let name = GAPCompleteLocalName(name: "BTStack " + address.description)
        let scanResponse: LowEnergyAdvertisingData = GAPDataEncoder.encode(name)
        
        print("Advertisment Name:", name.description)
        
        // Add services
        let (serviceHandle, _) = peripheral.add(service: GATTAttribute<BTStackPeripheral.Data>.Service(
            uuid: .deviceInformation,
            isPrimary: true,
            characteristics: [
                .init(
                    uuid: .deviceName,
                    value: Array("BTStack BLE Peripheral".utf8),
                    permissions: .read,
                    properties: [.read]
                )
            ]
        ))
        defer {
            peripheral.remove(service: serviceHandle)
        }
        // 
        try peripheral.start(options: .init(
            advertisingData: advertisement,
            scanResponse: scanResponse)
        )
        
        while true {
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
}
