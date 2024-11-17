//
//  L2CAP.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import CBTStack
import Bluetooth

public final class L2CAP {
    
    public nonisolated(unsafe) static var shared = L2CAP()
    
    internal var callbackRegistration = btstack_packet_callback_registration_t()
    
    internal var services = [UInt16: Service]()
    
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
    
    public func register(
        psm: UInt16,
        mtu: UInt16,
        security: gap_security_level_t
    ) {
        
    }
    
    public func unregister(psm: UInt16) {
        
    }
}

public extension L2CAP {
    
    struct Channel {
        
        public let id: UInt16
        
        
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
            l2cap_unregister_service(psm)
        }
    }
}

internal func _l2cap_packet_handler(
    packetType: UInt8,
    channel: UInt16,
    packetPointer: UnsafeMutablePointer<UInt8>?,
    packetSize: UInt16
) {
    
    
}
