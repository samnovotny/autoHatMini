//
//  i2c-dev.swift
//  
//
//  Created by Sam Novotny on 06/03/2020.
//

import Foundation

let I2C_SLAVE: UInt = 0x0703    /* Use this slave address */
let I2C_SMBUS_READ: UInt8 = 1
let I2C_SMBUS_WRITE: UInt8 = 0
let I2C_SMBUS_BYTE_DATA: Int32 = 2
let I2C_SMBUS_WORD_DATA: Int32 = 3
let I2C_SMBUS_BLOCK_MAX = 32
let I2C_SMBUS = 0x0720          /* SMBus transfer */

/// i2c_smbus_ioctl_data
//
struct i2c_smbus_ioctl_data {
    private var buffer = [UInt8] (repeating:0, count: 12)
    var data = [UInt8] (repeating: 0, count: I2C_SMBUS_BLOCK_MAX + 2)

    init(read_write: UInt8, command: UInt8, size: Int32) {
        // set read/write byte
        buffer[0] = read_write
        
        // set command
        buffer[1] = command
        
        // set Padding
        var p: Int16 = 1
        let pData = Data(bytes: &p, count: MemoryLayout<Int16>.size)
        var offset = 2
        for byte in pData {
            buffer[offset] = byte
            offset += 1
        }
        
        // set size
        var i: Int32 = size
        let intData = Data(bytes: &i, count: MemoryLayout<Int32>.size)
         for byte in intData {
            buffer[offset] = byte
            offset += 1
        }
        
        // set pointer to data array
        var pointerToData = UnsafeMutablePointer<UInt8> (&self.data)
        let pointer = Data(bytes: &pointerToData, count: MemoryLayout<UnsafeMutablePointer<UInt8>>.size)
        for byte in pointer {
            buffer[offset] = byte
            offset += 1
        }
        print("Pointer: \(UnsafeMutablePointer<UInt8> (&self.data))")
    }
    
    /// Print out the data
    //
    func dump() {
        print("Sent structure: ", terminator: "")
        for b in buffer {
            print(Int(b).hex8() ,terminator: " ")
        }
        print()
        print("Buffer: \(Int(self.data[0]).hex8()) \(Int(self.data[1]).hex8())")
    }
    
    /// Word value of buffer
    //
    var word: UInt16 {
        get {
            return((UInt16(data[0]) << 8) | (UInt16(data[1]) & 0xff))
        }
        set {
            data[0] = UInt8(newValue >> 8)
            data[1] = UInt8(newValue & 0xff)
        }
    }
    
    /// Byte vlue of buffer
    //
    var byte: UInt8 {
        get {
            return(data[0])
        }
        set {
            data[0] = newValue
        }
    }
}

//
func i2c_smbus_access(fd: Int32, rw: UInt8, command: UInt8, size: Int32, ptr: UnsafeMutableRawPointer) -> Int32 {
    return(0)
}

//
func i2c_smbus_write_byte_data(fd: Int32, command: UInt8, byte: UInt8) -> Int32 {
    var i2c = i2c_smbus_ioctl_data(read_write: I2C_SMBUS_WRITE, command: 0, size: I2C_SMBUS_BYTE_DATA)
    i2c.byte = byte
    print(#function)
    i2c.dump()
    let io = ioctl(CInt(fd), UInt(I2C_SMBUS), &i2c.data)
    guard io == 0 else {return(-1)}
    return (io)
}

//
func i2c_smbus_write_word_data(fd: Int32, command: UInt8, word: UInt16) -> Int32 {
    var i2c = i2c_smbus_ioctl_data(read_write: I2C_SMBUS_WRITE, command: 0, size: I2C_SMBUS_WORD_DATA)
    i2c.word = word
    print(#function)
    i2c.dump()
    let io = ioctl(CInt(fd), UInt(I2C_SMBUS), &i2c.data)
    guard io == 0 else {return(-1)}
    return (io)
}

//
func i2c_smbus_read_word_data(fd: Int32, command: UInt8) -> Int32 {
    var i2c = i2c_smbus_ioctl_data(read_write: I2C_SMBUS_READ, command: 0, size: I2C_SMBUS_WORD_DATA)
    let io = ioctl(CInt(fd), UInt(I2C_SMBUS), &i2c.data)
    guard io == 0 else {return(-1)}
    print(#function)
    i2c.dump()
    return (Int32(i2c.word))
}
