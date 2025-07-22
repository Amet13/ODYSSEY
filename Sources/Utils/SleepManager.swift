import Foundation
import IOKit.pwr_mgt

/**
 SleepManager provides static methods to prevent and allow system sleep, used for keeping the Mac awake during critical operations (e.g., autorun reservations).
 */
@MainActor
public enum SleepManager {
    private static var assertionID: IOPMAssertionID = 0

    /**
     Prevents the Mac from sleeping for the given reason.
     - Parameter reason: The reason for preventing sleep (shown in Activity Monitor).
     */
    public static func preventSleep(reason: String) {
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

    /**
     Allows the Mac to sleep again, releasing any previous sleep prevention assertion.
     */
    public static func allowSleep() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            print("Sleep allowed")
        }
    }
}
