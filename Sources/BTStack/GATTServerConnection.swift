//
//  GATTServerConnection.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/17/24.
//

#if canImport(Foundation)
import Foundation
#endif
#if canImport(BluetoothGATT)
import Bluetooth
import BluetoothGATT
import GATT

internal final class GATTServerConnection <Socket: L2CAPConnection>: @unchecked Sendable {
    
    typealias Data = Socket.Data
    
    typealias Error = Socket.Error
    
    // MARK: - Properties
    
    public let central: GATT.Central
        
    private let server: GATTServer<Socket>
    
    public var maximumUpdateValueLength: Int {
        // ATT_MTU-3
        Int(server.maximumTransmissionUnit.rawValue) - 3
    }
    
    #if canImport(Foundation)
    private let lock = NSLock()
    #endif
    
    // MARK: - Initialization
    
    internal init(
        central: Central,
        socket: Socket,
        maximumTransmissionUnit: ATTMaximumTransmissionUnit,
        maximumPreparedWrites: Int,
        database: GATTDatabase<Socket.Data>,
        callback: GATTServer<Socket>.Callback,
        log: (@Sendable (String) -> ())?
    ) {
        self.central = central
        self.server = GATTServer(
            socket: socket,
            maximumTransmissionUnit: maximumTransmissionUnit,
            maximumPreparedWrites: maximumPreparedWrites,
            database: database,
            log: log
        )
        self.server.callback = callback
    }
    
    // MARK: - Methods
    
    /// Modify the value of a characteristic, optionally emiting notifications if configured on active connections.
    public func write(_ value: Data, forCharacteristic handle: UInt16) {
        #if canImport(Foundation)
        lock.lock()
        defer { lock.unlock() }
        #endif
        server.writeValue(value, forCharacteristic: handle)
    }
    
    public func run() throws(ATTConnectionError<Socket.Error, Socket.Data>) {
        #if canImport(Foundation)
        lock.lock()
        defer { lock.unlock() }
        #endif
        try self.server.run()
    }
    
    public subscript(handle: UInt16) -> Data {
        #if canImport(Foundation)
        lock.lock()
        defer { lock.unlock() }
        #endif
        return server.database[handle: handle].value
    }
}

#endif
