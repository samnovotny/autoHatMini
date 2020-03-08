import Foundation

print("Hello, \(#function) world!")

let adc = ADS1015()

while true {
    do {
        for n in 1...3 {
            if let value = try adc?.readADC(channel: n) {
                print("adc(\(n)) = \(String(format: "%0.2f", value))")
            }
        }
    }
    catch {
        print("ADC error \(error)")
    }
    print("------")
    Thread.sleep(forTimeInterval: 1.5)
}
