//
//  HostController.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import Bluetooth
import CBTStack

public final class HostController {
    
    nonisolated(unsafe) public static let shared = HostController()
    
    private var callbackRegistration = btstack_packet_callback_registration_t()

    fileprivate(set) var state: State = .off
    
    private init() {
        // register for callbacks
        callbackRegistration.callback = _bluetooth_packet_handler
        hci_add_event_handler(&callbackRegistration)
    }

    deinit {
        hci_remove_event_handler(&callbackRegistration)
    }
}

extension HostController {

    enum PowerState: UInt8, Sendable {

        case off    = 0
        case on     = 1
        case sleep  = 2
    }

    enum State: UInt8 {

        case off            = 0
        case initializing   = 1
        case on             = 2
        case halting        = 3
        case sleeping       = 4
        case fallingAsleep  = 5
    }
}

// packet_handler(uint8_t packet_type, uint16_t channel, uint8_t *packet, uint16_t size)
@_documentation(visibility: internal)
@_cdecl("bluetooth_packet_handler")
internal func _bluetooth_packet_handler(packetType: UInt8, channel: UInt16, packetPointer: UnsafeMutablePointer<UInt8>?, packetSize: UInt16) {
    
    switch packetType {
        case UInt8(HCI_EVENT_PACKET):
            switch hci_event_packet_get_type(packetPointer) {
                case UInt8(BTSTACK_EVENT_STATE):
                    let rawState = btstack_event_state_get_state(packetPointer)
                let newValue = HostController.State(rawValue: rawState) ?? .off
                    HostController.shared.state = newValue
                case UInt8(HCI_EVENT_VENDOR_SPECIFIC):
                    break
                default:
                    break
            }
        default:
            break
    }
}
