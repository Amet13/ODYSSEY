import Foundation
import os

/// Form handling and field filling JavaScript functions for ODYSSEY
/// Contains all form-related automation functionality
@MainActor
public final class JavaScriptForms {
  private let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "JavaScriptForms")

  /// Form handling library
  public static let formsLibrary = """
    // ===== FORM FILLING =====

    // Fill all contact fields using browser autofill and click confirm with delay
    fillContactFields: function(phoneNumber, email, name) {
        try {
            // Fill all fields with browser autofill simulation
            const phoneResult = this.fillFormField('phone', phoneNumber);
            const emailResult = this.fillFormField('email', email);
            const nameResult = this.fillFormField('name', name);

            const allFieldsFilled = phoneResult && emailResult && nameResult;

            if (allFieldsFilled) {
                // Simulate human behavior before clicking confirm button using existing functions
                // 1. Random mouse movement
                this.simulateQuickMouseMovement();

                // 2. Small scroll
                this.simulateQuickScrolling();

                return {
                    success: true,
                    filledCount: 3,
                    confirmClicked: false
                };
            } else {
                return {
                    success: false,
                    error: 'Failed to fill all fields',
                    filledCount: [phoneResult, emailResult, nameResult].filter(Boolean).length
                };
            }
        } catch (error) {
            console.error('[ODYSSEY] Error in fillContactFields:', error);
            return {
                success: false,
                error: error.message || 'Unknown error in fillContactFields'
            };
        }
    },
    """
}
