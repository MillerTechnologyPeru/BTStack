//
//  L2CAP.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import CBTStack
import Bluetooth
import BluetoothGATT

public final class L2CAP {
    
    public nonisolated(unsafe) static var shared = L2CAP()
    
    internal var callbackRegistration = btstack_packet_callback_registration_t()
    
    internal var services = [UInt16: Service]()
    
    public var log: (@Sendable (String) -> ())?
    
    internal fileprivate(set) var recievedData = [UInt16: [[UInt8]]]()
    
    private init() {
        // Set up L2CAP and register L2CAP with HCI layer.
        l2cap_init()
        // register for callbacks
        callbackRegistration.callback = _l2cap_packet_handler
        l2cap_add_event_handler(&callbackRegistration)
    }
    
    deinit {
        l2cap_remove_event_handler(&callbackRegistration)
    }
    
    public var maxMTU: UInt16 {
        get { l2cap_max_mtu() }
    }
    
    public var maxLowEnergyMTU: UInt16 {
        get { l2cap_max_le_mtu() }
        set { l2cap_set_max_le_mtu(newValue) }
    }
    
    public func register(channel: UInt16) {
        l2cap_register_fixed_channel(_l2cap_packet_handler, channel)
    }
    
    public func registerBREDR(
        psm: UInt16,
        mtu: UInt16,
        security: gap_security_level_t
    ) throws(BTStackError) {
        try l2cap_register_service(_l2cap_packet_handler, psm, mtu, security).throwsError()
    }
    
    public func unregisterBREDR(psm: UInt16) throws(BTStackError) {
        try l2cap_unregister_service(psm).throwsError()
    }
    
    public func registerLowEnergy(
        psm: UInt16,
        security: gap_security_level_t
    )  throws(BTStackError) {
        try l2cap_le_register_service(_l2cap_packet_handler, psm, security).throwsError()
    }
    
    public func unregisterLowEnergy(psm: UInt16) throws(BTStackError) {
        try l2cap_le_unregister_service(psm).throwsError()
    }
    
    public func disconnect(connection: UInt16) throws(BTStackError) {
        try l2cap_disconnect(connection).throwsError()
    }
    
    public func canRead(connection handle: UInt16) -> Bool {
        self.recievedData[handle, default: []].isEmpty == false
    }
    
    public func read(length: Int = 23, connection handle: UInt16) -> [UInt8]? {
        guard canRead(connection: handle) else {
            return nil
        }
        return self.recievedData[handle, default: []].removeFirst()
    }
    
    internal func recieved(_ connection: UInt16, _ buffer: UnsafeBufferPointer<UInt8>) {
        let data = Array(buffer)
        self.recievedData[connection, default: []].append(data)
    }
    
    public func canWrite(connection handle: UInt16) -> Bool {
        l2cap_can_send_packet_now(handle)
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, connection handle: UInt16) throws(BTStackError) {
        try l2cap_send(handle, buffer.baseAddress, UInt16(buffer.count)).throwsError()
    }
}

public extension L2CAP {
    
    final class Service {
        
        public let psm: UInt16
        
        fileprivate init(
            psm: UInt16,
            mtu: UInt16,
            security: gap_security_level_t
        ) {
            self.psm = psm
            l2cap_register_service(_l2cap_packet_handler, psm, mtu, security)
        }
        
        deinit {
            close()
        }
        
        public func close() {
            l2cap_unregister_service(psm)
        }
    }
}

internal func _l2cap_packet_handler(
    packetType: UInt8,
    connection: UInt16,
    packetPointer: UnsafeMutablePointer<UInt8>?,
    packetSize: UInt16
) {
    let l2cap = L2CAP.shared
    let buffer = UnsafeBufferPointer(start: packetPointer, count: Int(packetSize))
    switch Int32(packetType) {
        case HCI_EVENT_PACKET:
            switch UInt32(hci_event_packet_get_type(packetPointer)) {
                case L2CAP_EVENT_INCOMING_CONNECTION:
                    break
                case L2CAP_EVENT_CHANNEL_OPENED:
                    break
                case L2CAP_EVENT_CHANNEL_CLOSED:
                    break
                case L2CAP_EVENT_CAN_SEND_NOW:
                    break
                default:
                    break
            }
        case Int32(L2CAP_DATA_PACKET):
            l2cap.handle_L2CAP_DATA_PACKET(connection, buffer)
        case Int32(ATT_DATA_PACKET):
            l2cap.handle_ATT_DATA_PACKET(connection, buffer)
        default:
            break
    }
}

internal extension L2CAP {
    
    func handle_L2CAP_DATA_PACKET(_ connection: UInt16, _ data: UnsafeBufferPointer<UInt8>) {
        log?("L2CAP Packet, handle \(connection)")
        recieved(connection, data)
    }
    
    func handle_ATT_DATA_PACKET(_ connection: UInt16, _ data: UnsafeBufferPointer<UInt8>) {
        log?("ATT Packet, handle \(connection)")
        guard data.isEmpty == false, let opcode = ATTOpcode(rawValue: data[0]) else {
            return
        }
        log?("ATT Opcode \(opcode)")
        recieved(connection, data)
    }
}
