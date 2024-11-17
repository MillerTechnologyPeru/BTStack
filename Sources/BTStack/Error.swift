//
//  Error.swift
//  BTStack
//
//  Created by Alsey Coleman Miller on 11/17/24.
//

import BluetoothHCI

/// BTstack Error Code
public struct BTStackError: Error, RawRepresentable, Equatable, Hashable, Sendable {
    
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public extension HCIError {
    
    init?(_ error: BTStackError) {
        guard error.rawValue <= UInt8.max else {
            return nil
        }
        self.init(rawValue: UInt8(error.rawValue))
    }
}

internal extension CInt {
    
    func throwsError() throws(BTStackError) {
        guard self == 0 else {
            throw BTStackError(rawValue: self)
        }
    }
}

internal extension UInt8 {
    
    func throwsError() throws(BTStackError) {
        guard self == 0 else {
            throw BTStackError(rawValue: numericCast(self))
        }
    }
}
