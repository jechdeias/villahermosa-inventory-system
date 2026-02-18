/// Type validation utilities for the Villahermosa Inventory System
/// 
/// Provides validation methods for common data types and business rules
class TypeValidator {
  /// Ensures a value is a valid UUID string
  static String ensureUuid(String value) {
    if (value.isEmpty) {
      throw ArgumentError('UUID cannot be empty');
    }
    // Basic UUID format validation
    final uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (!uuidPattern.hasMatch(value)) {
      throw ArgumentError('Invalid UUID format: $value');
    }
    return value;
  }

  /// Ensures a value is a valid integer ID
  static int ensureIntId(dynamic value) {
    if (value is int) {
      if (value <= 0) {
        throw ArgumentError('ID must be positive: $value');
      }
      return value;
    }
    if (value is String) {
      final id = int.tryParse(value);
      if (id == null || id <= 0) {
        throw ArgumentError('Invalid integer ID: $value');
      }
      return id;
    }
    throw ArgumentError('ID must be an integer or numeric string: $value');
  }

  /// Validates stock quantity is positive and reasonable
  static int validateStockQuantity(int quantity) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be positive: $quantity');
    }
    if (quantity > 10000) {
      throw ArgumentError('Quantity too large: $quantity (max 10000)');
    }
    return quantity;
  }

  /// Validates price is positive and reasonable
  static double validatePrice(double price) {
    if (price <= 0) {
      throw ArgumentError('Price must be positive: $price');
    }
    if (price > 1000000) {
      throw ArgumentError('Price too large: $price (max 1,000,000)');
    }
    return price;
  }

  /// Ensures an object exists (not null)
  static void ensureExists(dynamic object, String typeName, String identifier) {
    if (object == null) {
      throw Exception('$typeName not found: $identifier');
    }
  }

  /// Validates email format
  static String validateEmail(String email) {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailPattern.hasMatch(email)) {
      throw ArgumentError('Invalid email format: $email');
    }
    return email;
  }

  /// Validates phone number format (basic validation)
  static String validatePhone(String phone) {
    if (phone.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phonePattern = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phonePattern.hasMatch(cleanPhone)) {
      throw ArgumentError('Invalid phone number format: $phone');
    }
    return phone;
  }

  /// Validates that a string is not empty
  static String validateNonEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName cannot be empty');
    }
    return value.trim();
  }

  /// Validates string length
  static String validateStringLength(String value, String fieldName, int minLength, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      throw ArgumentError('$fieldName must be at least $minLength characters');
    }
    if (trimmed.length > maxLength) {
      throw ArgumentError('$fieldName must be at most $maxLength characters');
    }
    return trimmed;
  }
}
