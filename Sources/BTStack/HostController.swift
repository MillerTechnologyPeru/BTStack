//
//  HostController.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import Bluetooth
import CBTStack

public final class HostController {
    
    public nonisolated(unsafe) static let `default` = HostController()
    
    // MARK: - Properties
    
    private var callbackRegistration = btstack_packet_callback_registration_t()
    
    public var log: (@Sendable (String) -> ())?

    public internal(set) var state: State = .off {
        didSet {
            log?("HCI State: \(oldValue) -> \(state)")
        }
    }
    
    public var isAdvertising = false {
        didSet {
            setAdvertisementState()
        }
    }
    
    public var advertisement = LowEnergyAdvertisingData() {
        didSet {
            setAdvertisementData()
        }
    }
    
    internal var advertisementBuffer = [UInt8]()
    
    public var scanResponse = LowEnergyAdvertisingData() {
        didSet {
            setScanResponse()
        }
    }
    
    internal var scanResponseBuffer = [UInt8]()
    
    // MARK: - Initialization
    
    private init() {
        // init BTStack
        #if os(macOS) || os(Linux)
        hci_init(hci_transport_usb_instance(), nil)
        #endif
        // register for callbacks
        callbackRegistration.callback = _bluetooth_packet_handler
        hci_add_event_handler(&callbackRegistration)
    }

    deinit {
        hci_remove_event_handler(&callbackRegistration)
        hci_deinit()
    }
    
    // MARK: - Methods
    
    public func setPower(_ state: PowerState) {
        hci_power_control(.init(rawValue: numericCast(state.rawValue)))
    }
}

// MARK: - Supporting Types

public extension HostController {

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
    
    let hostController = HostController.default
    let log = hostController.log
    switch packetType {
        case UInt8(HCI_EVENT_PACKET):
            switch hci_event_packet_get_type(packetPointer) {
                case UInt8(BTSTACK_EVENT_STATE):
                    hostController.handle_BTSTACK_EVENT_STATE(packetType, channel, packetPointer, packetSize)
                case UInt8(HCI_EVENT_TRANSPORT_USB_INFO):
                    hostController.handle_HCI_EVENT_TRANSPORT_USB_INFO(packetType, channel, packetPointer, packetSize)
                case UInt8(HCI_EVENT_VENDOR_SPECIFIC):
                    break
                default:
                    break
            }
        default:
            break
    }
}

internal extension HostController {
    
    func handle_BTSTACK_EVENT_STATE(_ packetType: UInt8, _ channel: UInt16, _ packetPointer: UnsafeMutablePointer<UInt8>?, _ packetSize: UInt16) {
        let rawState = btstack_event_state_get_state(packetPointer)
        let newValue = HostController.State(rawValue: rawState) ?? .off
        self.state = newValue
    }
    
    func handle_HCI_EVENT_TRANSPORT_USB_INFO(_ packetType: UInt8, _ channel: UInt16, _ packetPointer: UnsafeMutablePointer<UInt8>?, _ packetSize: UInt16) {
        let vendor = hci_event_transport_usb_info_get_vendor_id(packetPointer)
        let product = hci_event_transport_usb_info_get_product_id(packetPointer)
        log?("USB Vendor \(vendor) Product \(product) ")
    }
}
