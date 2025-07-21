import Foundation
import IOKit.pwr_mgt

@MainActor
enum SleepManager {
    private static var assertionID: IOPMAssertionID = 0

    static func preventSleep(reason: String) {
        let reasonForActivity = reason as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &assertionID,
            )
        if result == kIOReturnSuccess {
            print("Sleep prevented: \(reason)")
        }
    }

    static func allowSleep() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            print("Sleep allowed")
        }
    }
}
