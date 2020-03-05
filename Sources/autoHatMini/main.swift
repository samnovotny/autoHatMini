import Foundation

print(String(format: "Hello, %s world!", #function))

internal let portString = "/dev/i2c-1"
internal let deviceAddress = 0x48

let adc = I2CIo(address: deviceAddress, device: portString)

while true {
    do {
        for n in 0...2 {
            if let value = try adc?.readADC(channel: n) {
                print("adc(\(n)) = \(String(format: "%0.2f", value))")
            }
        }
    }
    catch {
        print("ADC error \(error)")
    }
    Thread.sleep(forTimeInterval: 5)
}
