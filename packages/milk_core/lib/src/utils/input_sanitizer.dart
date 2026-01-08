/// Input Sanitization Utilities
/// Prevents XSS and injection attacks

class InputSanitizer {
  /// Sanitize text input - removes dangerous characters
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;
    
    // Remove HTML tags
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Escape dangerous characters
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
    
    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }
  
  /// Sanitize address input
  static String sanitizeAddress(String address) {
    if (address.isEmpty) return address;
    
    // Allow common address characters
    String sanitized = address.replaceAll(RegExp(r'[^\w\s,.\-#/()]'), '');
    
    // Limit length
    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }
    
    return sanitized.trim();
  }
  
  /// Sanitize phone number - only digits and +
  static String sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }
  
  /// Sanitize email
  static String sanitizeEmail(String email) {
    // Remove spaces and convert to lowercase
    return email.trim().toLowerCase();
  }
  
  /// Sanitize name - only letters, spaces, and common name characters
  static String sanitizeName(String name) {
    if (name.isEmpty) return name;
    
    // Allow letters, spaces, hyphens, apostrophes
    String sanitized = name.replaceAll(RegExp(r"[^\p{L}\s\-']", unicode: true), '');
    
    // Limit length
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }
    
    return sanitized.trim();
  }
  
  /// Validate PIN code (Indian format)
  static bool isValidPinCode(String pin) {
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin);
  }
  
  /// Validate Indian phone number
  static bool isValidIndianPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    return cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'));
  }
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }
}
