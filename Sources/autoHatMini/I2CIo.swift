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


/// ADS1015 setting bits
//
internal let SAMPLES_PER_SECOND_MAP: Dictionary<Int, UInt16> = [128: 0x0000, 250: 0x0020, 490: 0x0040, 920: 0x0060, 1600: 0x0080, 2400: 0x00A0, 3300: 0x00C0]
internal let CHANNEL_MAP: Dictionary<Int, UInt16> = [0: 0x4000, 1: 0x5000, 2: 0x6000]
internal let PROGRAMMABLE_GAIN_MAP: Dictionary<Int, UInt16> = [6144: 0x0000, 4096: 0x0200, 2048: 0x0400, 1024: 0x0600, 512: 0x0800, 256: 0x0A00]

/// Constants for this device / application
//
internal let samplesPerSecond = 1600
internal let programmableGain = 4096

/// I2C object to handle the ADS1015 ADC
//
class I2CIo {
    
    let fd: Int32
    let address: Int
    
    /// Intitialiser
    /// - Parameter address: Hex address to which the device is hardwired
    /// - Parameter device: Linux device string identifying the port
    //    
    init?(address: Int, device: String) {
        self.address = address
        self.fd = open(device, O_RDWR)
        guard self.fd > 0 else { return nil }
    }
    
    deinit {
        print ("\(#function)")
        close(self.fd)
    }
    
    /// Select the I2c slave for forthoming transmision.
    
    private func selectDevice() throws {
        let io = ioctl(self.fd, UInt(I2C_SLAVE), CInt(self.address))
        guard io != -1 else {throw I2CError.ioctlError}
    }
    
    /// Create the mask to set the ADC
    /// - Parameter channel: The channel (1-3) to generate the mask for
    
    private func getConfig(channel: Int) -> UInt16 {
        var config: UInt16 = 0x8000 | 0x0003 | 0x0100
        config |= SAMPLES_PER_SECOND_MAP[samplesPerSecond]!
        config |= PROGRAMMABLE_GAIN_MAP[programmableGain]!
        config |= CHANNEL_MAP[channel-1]!

        print("config = \(Int(config).hex16()),\(Int(config).binaryWord())")
        return config
    }
    
    /// Read the ADC for the given channel
    /// - Parameter channel: select the channel to run the ADC for
    //
    func readADC(channel: Int) throws -> Float {
        print ("\(#function) - \(channel)", terminator: " ")
 
        try selectDevice()
        
        /// Configure ADC to read and trigger conversion
        let io = i2c_smbus_write_word_data(fd: self.fd,command:  0,word:  getConfig(channel: channel))
        guard io != -1 else {throw I2CError.writeError}
        
        /// Wait a bit
        let delay = (1.0 / 1600.0) + 0.0001
        Thread.sleep(forTimeInterval: delay)
        
        /// Get the data and shift right four
        let readData = i2c_smbus_read_word_data(fd: self.fd, command: 0)        
        guard readData != -1 else {throw I2CError.readError}
        let intValue = Int(readData >> 4)
        
        print( "intValue(\(intValue)) = \(intValue.binaryWord())")
        
        
        /// Scale the conversion
        let result = Float(intValue) / 2047.0 * Float(programmableGain) / 3300.0        
        return (result)
    }
    
    /// Read the configuration register
    //
    func readConfig() throws -> UInt16 {
        print ("\(#function)")
        
        try selectDevice()
        
        let io = i2c_smbus_write_byte_data(fd: self.fd, command: 0, byte: 1)
        guard io != -1 else {throw I2CError.writeError}
        
        let readData = i2c_smbus_read_word_data(fd: self.fd, command: 0)
        guard readData != -1 else {throw I2CError.readError}
        return(UInt16(readData))
    }
}

