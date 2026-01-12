// lib/utils/email_validator.dart

class EmailValidator {
  // List of allowed email domains (trusted providers)
  static final List<String> _allowedDomains = [
    // Popular email providers
    'gmail.com',
    'yahoo.com',
    'yahoo.co.uk',
    'yahoo.co.in',
    'hotmail.com',
    'outlook.com',
    'live.com',
    'msn.com',
    'icloud.com',
    'me.com',
    'mac.com',
    'aol.com',
    'protonmail.com',
    'proton.me',
    'zoho.com',
    'yandex.com',
    'mail.com',
    
    // Educational domains
    'edu',
    'ac.uk',
    'edu.ph',
    
    // Business domains (you can add more)
    'company.com',
  ];

  // List of known disposable/temporary email providers
  static final List<String> _disposableDomains = [
    '10minutemail.com',
    'guerrillamail.com',
    'mailinator.com',
    'tempmail.com',
    'throwaway.email',
    'temp-mail.org',
    'fakeinbox.com',
    'maildrop.cc',
    'yopmail.com',
    'getnada.com',
    'trashmail.com',
    'sharklasers.com',
    'guerrillamail.info',
    'grr.la',
    'guerrillamail.biz',
    'guerrillamail.de',
    'mailnesia.com',
    'mytemp.email',
    'mohmal.com',
    'emailondeck.com',
    'mintemail.com',
  ];

  /// Validates if email domain is allowed
  static bool isValidEmailDomain(String email) {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return false;
      }

      final domain = email.split('@')[1].toLowerCase();
      
      // Check if it's a disposable email
      if (isDisposableEmail(email)) {
        return false;
      }

      // Check if domain is in allowed list
      // Also check if it ends with allowed domain (for subdomains)
      for (var allowedDomain in _allowedDomains) {
        if (domain == allowedDomain || domain.endsWith('.$allowedDomain')) {
          return true;
        }
      }

      // Additional check for .edu domains
      if (domain.endsWith('.edu') || domain.endsWith('.edu.ph')) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Checks if email is from a disposable email provider
  static bool isDisposableEmail(String email) {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return false;
      }

      final domain = email.split('@')[1].toLowerCase();

      return _disposableDomains.any((disposable) => 
        domain == disposable || domain.endsWith('.$disposable')
      );
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message for invalid domain
  static String getEmailDomainError(String email) {
    if (isDisposableEmail(email)) {
      return 'Temporary/disposable email addresses are not allowed';
    }
    return 'Please use a valid email address from trusted providers (Gmail, Yahoo, Outlook, etc.)';
  }

  /// Get the domain from email
  static String? getDomain(String email) {
    try {
      if (email.isEmpty || !email.contains('@')) {
        return null;
      }
      return email.split('@')[1].toLowerCase();
    } catch (e) {
      return null;
    }
  }

  /// Get list of allowed domains (for display purposes)
  static List<String> getAllowedDomains() {
    return List.unmodifiable(_allowedDomains);
  }
}