//
//  Transport.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/16/24.
//

import CBTStack

public extension HostController {
    
    struct Transport {
        
        internal let pointer: UnsafePointer<hci_transport_t>
        
        internal init(_ pointer: UnsafePointer<hci_transport_t>) {
            self.pointer = pointer
        }
    }
}

public extension HostController.Transport {
    
    /// USB Transport
    static var usb: HostController.Transport { .init(hci_transport_usb_instance()) }
}
