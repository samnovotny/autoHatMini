import Foundation

print("Hello, \(#function) world!")

internal let portString = "/dev/i2c-1"
internal let deviceAddress = 0x48

let adc = I2CIo(address: deviceAddress, device: portString)

//while true {
    do {
//        for n in 1...3 {
//            if let value = try adc?.readADC(channel: n) {
//                print("adc(\(n)) = \(String(format: "%0.2f", value))")
//            }
//        }
        if let value = try adc?.readConfig() {
            print("\(String(format: "%04x", value))")
        }
    }
    catch {
        print("ADC error \(error)")
    }
    Thread.sleep(forTimeInterval: 5)
//}
