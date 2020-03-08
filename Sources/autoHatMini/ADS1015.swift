//
//  ADC1015.swift
//  
//
//  Created by Sam Novotny on 24/02/2020.
//

import Foundation

/// Thrown IO errors
//
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
internal let maxVoltage: Float = 25.85

internal let I2C_SLAVE: UInt = 0x703
internal let ADS_1015_CONGIG_REG: UInt8 = 1
internal let ADS_1015_CONVERSION_REG: UInt8 = 0

/// I2C object to handle the ADS1015 ADC
//
class ADS1015 {
    
    let fd: Int32
    let address: Int
    
    /// Intitialiser
    /// - Parameter address: Hex address to which the device is hardwired
    /// - Parameter device: Linux device string identifying the port
    //    
    init?(address: Int = 0x48, device: String = "/dev/i2c-1") {
        self.address = address
        self.fd = open(device, O_RDWR)
        guard self.fd > 0 else { return nil }
    }
    
    deinit {
        print ("\(#function)")
        close(self.fd)
    }
    
    /// Select the I2c slave for forthoming transmision.
    
    private func setSlave() throws {
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

//        print("config = \(Int(config).hex16()),\(Int(config).binaryWord())")
        return config
    }
    
    /// Read the ADC for the given channel
    /// - Parameter channel: select the channel to run the ADC for
    //
    func readADC(channel: Int) throws -> Float {
//        print ("\(#function) - \(channel)", terminator: " ")
 
        //  Set address pointer register to Config register AND write the config
        try setSlave()
        var configBuffer = [UInt8] (repeating: 0, count: 3)
        configBuffer[0] = ADS_1015_CONGIG_REG
        let config = getConfig(channel: channel)
        configBuffer[1] = UInt8(config >> 8)
        configBuffer[2] = UInt8(config & 0xff)
        var io = write(self.fd, &configBuffer, configBuffer.count)
        guard io != -1 else {throw I2CError.writeError}

        /// Wait a bit
        let delay = (1.0 / Double(samplesPerSecond)) + 0.0001
        Thread.sleep(forTimeInterval: delay)

        //  Set address pointer register to Conversion register
        try setSlave()
        var pointerBuffer = [UInt8] (repeating: 0, count: 1)
        pointerBuffer[0] = ADS_1015_CONVERSION_REG
        io = write(self.fd, &pointerBuffer, pointerBuffer.count)
        guard io != -1 else {throw I2CError.writeError}

        // Read Conversion Register
        var conversionBuffer = [UInt8] (repeating: 0, count: 2)
        io = read(self.fd, &conversionBuffer, conversionBuffer.count)
        guard io != -1 else {throw I2CError.readError}
        
        /// Scale the conversion
//        print("[0]=\(Int(conversionBuffer[0]).hex8()), [1]=\(Int(conversionBuffer[1]).hex8())")
        let intValue = Int((UInt16(conversionBuffer[0]) << 4) | UInt16(conversionBuffer[1] >> 4))
//        print( "intValue = \(intValue), 0x\(intValue.hex16()), \(intValue.binaryWord())")
        let floatValue = (intValue & 0x800) == 0 ? Float(intValue) : Float(intValue - 4096)
//        print( "floatValue = \(floatValue)")
        let result = floatValue / 2047.0 * Float(programmableGain) / 3300.0 * maxVoltage
        return (result)
    }
    
    /// Read the configuration register
    //
    func readConfig() throws -> UInt16 {
        print ("\(#function)")
        
        //  Set address pointer register to Config register
        try setSlave()
        var pointerBuffer = [UInt8] (repeating: 0, count: 1)
        pointerBuffer[0] = ADS_1015_CONGIG_REG
        var io = write(self.fd, &pointerBuffer, pointerBuffer.count)
        guard io != -1 else {throw I2CError.writeError}
        
        // Read Config Register
        var configBuffer = [UInt8] (repeating: 0, count: 2)
        io = read(self.fd, &configBuffer, configBuffer.count)
        guard io != -1 else {throw I2CError.readError}
        let result = (UInt16(configBuffer[0]) << 8) | UInt16(configBuffer[1])
        return(result)
    }
}

