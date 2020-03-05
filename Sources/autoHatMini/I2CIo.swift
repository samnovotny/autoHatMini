//
//  I2CIo.swift
//  
//
//  Created by Sam Novotny on 24/02/2020.
//

import Foundation

enum I2CError : Error {
    case ioctlError
    case writeError
    case readError
}

/// Description
class I2CIo {
    
    let fd: Int32
    let address: Int

    init?(address: Int, device: String) {
        self.address = address
        self.fd = open(device, O_RDWR)
        guard self.fd > 0 else { return nil }
    }
    
    deinit {
        print ("\(#function)")
        close(self.fd)
    }
    
    /// Select the I2c slave for forthoming trasition.
    
    private func selectDevice() throws {
        let io = ioctl(self.fd, UInt(I2C_SLAVE), CInt(self.address))
        guard io != -1 else {throw I2CError.ioctlError}
    }
    
    /// Create mask to set the ADC
    /// - Parameter ch: The channel (1-3) indexed (0-2) to generate the mask for

    func config(ch: Int) -> UInt16 {
        let channels: [UInt16] = [0x4000, 0x5000, 0x6000]
        let config: UInt16 = 0x0003 | 0x0100 | 0x0080 | 0x0200 | 0x8000 | channels[ch]

        return(config)
    }
    
    /// Read the ADC for the given channel
    /// - Parameter channel: select the channel to run the ADC for
    
    func readADC(channel: Int) throws -> Float {
        print ("\(#function) - \(channel)", terminator: " ")
 
        try selectDevice()

        let io = i2c_smbus_write_word_data(self.fd, 0, config(ch: channel))
        guard io != -1 else {throw I2CError.writeError}
        
        let delay = (1.0 / 1600.0) + 0.0001
        Thread.sleep(forTimeInterval: delay)

        let readData = i2c_smbus_read_word_data(self.fd, 0)        
        guard readData != -1 else {throw I2CError.readError}

        let intValue = Int(readData >> 4)
        print( "intValue(\(intValue)) = \(intValue.binaryWord())")
        
        let result = Float(intValue) / 2047.0 * 4096.0 / 3.3
        
        return (result)
    }
}

