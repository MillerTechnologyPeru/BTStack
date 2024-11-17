//
//  GAP.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import Bluetooth
import CBTStack

public extension HostController {
    
    func setAdvertisementParameters(
        advIntMin: UInt16 = 0x0030,
        advIntMax: UInt16 = 0x0030,
        advType: UInt8 = 0,
        directAddressType: UInt8 = 0,
        directAddress: inout BluetoothAddress,
        channelMap: UInt8 = 0x07,
        filterPolicy: UInt8 = 0x00
    ) {
        withUnsafeMutablePointer(to: &directAddress.bytes) {
            gap_advertisements_set_params(advIntMin, advIntMax, advType, directAddressType, $0, channelMap, filterPolicy)
        }
    }
}

internal extension HostController {
    
    func setAdvertisementData() {
        let length = advertisement.length
        advertisementBuffer = [UInt8](advertisement)
        // data is not copied, pointer has to stay valid
        gap_advertisements_set_data(length, &advertisementBuffer)
    }
    
    func setScanResponse() {
        let length = scanResponse.length
        scanResponseBuffer = [UInt8](scanResponse)
        // data is not copied, pointer has to stay valid
        gap_scan_response_set_data(length, &scanResponseBuffer)
    }
    
    func setAdvertisementState() {
        gap_advertisements_enable(isAdvertising ? 1 : 0)
    }
}
