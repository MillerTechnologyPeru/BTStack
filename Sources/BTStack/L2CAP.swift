//
//  L2CAP.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import CBTStack
import Bluetooth
import BluetoothGATT
import BluetoothHCI

public final class L2CAP {
    
    public nonisolated(unsafe) static var shared = L2CAP()
    
    internal var l2capCallbackRegistration = btstack_packet_callback_registration_t()
    
    private var hciCallbackRegistration = btstack_packet_callback_registration_t()
        
    public var log: (@Sendable (String) -> ())?
    
    internal fileprivate(set) var recievedData = [UInt16: [[UInt8]]]()
    
    internal fileprivate(set) var pendingConnections = [UInt16]()
    
    private init() {
        // Set up L2CAP and register L2CAP with HCI layer.
        l2cap_init()
        // register for callbacks
        l2capCallbackRegistration.callback = _l2cap_packet_handler
        l2cap_add_event_handler(&l2capCallbackRegistration)
        hciCallbackRegistration.callback = _l2cap_packet_handler
        hci_add_event_handler(&hciCallbackRegistration)
    }
    
    deinit {
        l2cap_remove_event_handler(&l2capCallbackRegistration)
        hci_remove_event_handler(&hciCallbackRegistration)
    }
    
    public var maxMTU: UInt16 {
        get { l2cap_max_mtu() }
    }
    
    public var maxLowEnergyMTU: UInt16 {
        get { l2cap_max_le_mtu() }
        set { l2cap_set_max_le_mtu(newValue) }
    }
    
    public func register(channel: ChannelIdentifier) {
        l2cap_register_fixed_channel(_l2cap_packet_handler, channel.rawValue)
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
    
    public func canRead(_ handle: UInt16) -> Bool {
        self.recievedData[handle, default: []].isEmpty == false
    }
    
    public func read(length: Int = 23, connection handle: UInt16) -> [UInt8]? {
        guard canRead(handle) else {
            return nil
        }
        return Array(self.recievedData[handle, default: []].removeFirst().prefix(length))
    }
    
    internal func recieved(_ connection: UInt16, _ buffer: UnsafeBufferPointer<UInt8>) {
        let data = Array(buffer)
        self.recievedData[connection, default: []].append(data)
    }
    
    public func canWrite(_ handle: UInt16) -> Bool {
        l2cap_can_send_packet_now(handle)
    }
    
    public func write(_ buffer: UnsafeRawBufferPointer, connection handle: UInt16) throws(BTStackError) {
        try l2cap_send(handle, buffer.baseAddress, UInt16(buffer.count)).throwsError()
    }
    
    public func canAccept() -> Bool {
        pendingConnections.isEmpty == false
    }
    
    public func accept() -> UInt16? {
        guard canAccept() else {
            return nil
        }
        return self.pendingConnections.removeFirst()
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
                    let local_cid = l2cap_event_incoming_connection_get_local_cid(packetPointer)
                    l2cap_accept_connection(local_cid)
                case L2CAP_EVENT_CHANNEL_OPENED:
                    break
                case L2CAP_EVENT_CHANNEL_CLOSED:
                    break
                case L2CAP_EVENT_CAN_SEND_NOW:
                    break
                case HCI_EVENT_DISCONNECTION_COMPLETE:
                    l2cap.handle_HCI_EVENT_DISCONNECTION_COMPLETE(connection, buffer)
                case HCI_EVENT_META_GAP:
                    switch UInt32(hci_event_gap_meta_get_subevent_code(packetPointer)) {
                        case GAP_SUBEVENT_LE_CONNECTION_COMPLETE:
                        l2cap.handle_GAP_SUBEVENT_LE_CONNECTION_COMPLETE(connection, buffer)
                        default:
                            break
                }
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
        log?("L2CAP Packet - Handle \(connection)")
        recieved(connection, data)
    }
    
    func handle_ATT_DATA_PACKET(_ connection: UInt16, _ data: UnsafeBufferPointer<UInt8>) {
        log?("ATT Packet - Handle \(connection)")
        guard data.isEmpty == false, let opcode = ATTOpcode(rawValue: data[0]) else {
            return
        }
        log?("ATT Opcode \(opcode)")
        recieved(connection, data)
    }
    
    func handle_HCI_EVENT_DISCONNECTION_COMPLETE(_ connection: UInt16, _ data: UnsafeBufferPointer<UInt8>) {
        guard let event = HCIDisconnectionComplete(data: Array(data.suffix(from: 2))) else {
            assertionFailure()
            return
        }
        log?("Disconnected - \(event)")
        self.recievedData[event.handle] = nil
        self.pendingConnections.removeAll(where: { $0 == event.handle })
    }
    
    func handle_GAP_SUBEVENT_LE_CONNECTION_COMPLETE(_ connection: UInt16, _ data: UnsafeBufferPointer<UInt8>) {
        let connectionHandle = gap_subevent_le_connection_complete_get_connection_handle(data.baseAddress)
        log?("Connected - \(connectionHandle)")
        pendingConnections.append(connectionHandle)
    }
}
