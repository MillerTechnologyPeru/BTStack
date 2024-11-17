//
//  ATT.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/17/24.
//

import Bluetooth
import BluetoothGATT
import BluetoothHCI
import CBTStack

public extension L2CAP {
    
    struct Server: L2CAPServer {
                
        public typealias Error = BTStackError
        
        public let address: Bluetooth.BluetoothAddress
        
        public let psm: UInt16?
        
        public let channel: ChannelIdentifier?
        
        internal unowned let l2cap = L2CAP.shared
        
        /// Creates a new server,
        public static func lowEnergyServer(
            address: BluetoothAddress,
            isRandom: Bool,
            backlog: Int
        ) throws(BTStackError) -> Self {
            self.init(channel: .att)
        }
        
        public init(channel: ChannelIdentifier) {
            L2CAP.shared.register(channel: channel)
            self.address = HostController.default.address
            self.channel = channel
            self.psm = nil
        }
        
        public init(lowEnergy psm: UInt16) throws(BTStackError) {
            try L2CAP.shared.registerLowEnergy(psm: psm, security: LEVEL_0)
            self.address = HostController.default.address
            self.psm = psm
            self.channel = nil
        }
        
        public func close() {
            if let psm {
                try? L2CAP.shared.unregisterLowEnergy(psm: psm)
            }
        }
        
        public func accept() throws(BTStackError) -> Connection {
            guard let handle = L2CAP.shared.accept() else {
                throw BTStackError(.noConnection)
            }
            return Connection(
                handle: handle,
                address: address, // TODO: Remote address
                destination: self.address
            )
        }
        
        public var status: Bluetooth.L2CAPSocketStatus<BTStackError> {
            let l2cap = L2CAP.shared
            return .init(
                send: false,
                recieve: false,
                accept: l2cap.canAccept(),
                error: nil
            )
        }
    }
}

public extension L2CAP {
    
    struct Connection: L2CAPConnection {
        
        public typealias Error = BTStackError
        
        public typealias Data = [UInt8]
        
        public let handle: UInt16
                
        public let address: BluetoothAddress
        
        public let destination: BluetoothAddress
        
        internal unowned let l2cap = L2CAP.shared
        
        /// Creates a new socket connected to the remote address specified.
        public static func lowEnergyClient(
            address: BluetoothAddress,
            destination: BluetoothAddress,
            isRandom: Bool
        ) throws(BTStackError) -> Self {
            // TODO: Outgoing connection
            throw .init(.unspecifiedError)
        }
        
        public func close() {
            try? l2cap.disconnect(connection: handle)
        }
        
        /// Write to the socket.
        public func send(_ data: Data) throws(BTStackError) {
            do {
                try data.withUnsafeBytes {
                    try l2cap.write($0, connection: handle)
                }
            }
            catch {
                throw error as! BTStackError
            }
        }
        
        /// Reads from the socket.
        public func receive(_ bufferSize: Int) throws(Self.Error) -> Self.Data {
            guard let data = l2cap.read(length: bufferSize, connection: handle) else {
                throw BTStackError(.unspecifiedError)
            }
            return data
        }
            
        /// Attempts to change the socket's security level.
        public func setSecurityLevel(_ securityLevel: SecurityLevel) throws(Self.Error) {
            throw BTStackError(.unspecifiedError)
        }
        
        /// Get security level
        //var securityLevel: SecurityLevel { get throws(Self.Error) }
        public func securityLevel() throws(Self.Error) -> SecurityLevel {
            .sdp
        }
        
        public var status: Bluetooth.L2CAPSocketStatus<BTStackError> {
            return .init(
                send: l2cap.canWrite(handle),
                recieve: l2cap.canRead(handle),
                accept: false,
                error: nil
            )
        }
    }
}
