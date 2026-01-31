/// Type validation utilities to prevent ID type mismatches
class TypeValidator {
  /// Ensures a value is a valid UUID string
  static String ensureUuid(dynamic id) {
    if (id is String) {
      if (id.isEmpty) {
        throw ArgumentError('UUID cannot be empty');
      }
      return id;
    }
    if (id is int) {
      return id.toString();
    }
    throw ArgumentError('Invalid UUID type: ${id.runtimeType}, value: $id');
  }
  
  /// Ensures a value is a valid integer ID
  static int ensureIntId(dynamic id) {
    if (id is int) {
      if (id <= 0) {
        throw ArgumentError('Integer ID must be positive, got: $id');
      }
      return id;
    }
    if (id is String) {
      final parsed = int.tryParse(id);
      if (parsed == null) {
        throw ArgumentError('Cannot parse string to integer: "$id"');
      }
      return parsed;
    }
    throw ArgumentError('Invalid Integer ID type: ${id.runtimeType}, value: $id');
  }
  
  /// Validates that a record exists before proceeding
  static T ensureExists<T>(T? record, String entityType, dynamic id) {
    if (record == null) {
      throw ArgumentError('$entityType not found with ID: $id');
    }
    return record;
  }
  
  /// Validates stock quantity
  static int validateStockQuantity(int quantity, {bool allowNegative = false}) {
    if (!allowNegative && quantity < 0) {
      throw ArgumentError('Stock quantity cannot be negative: $quantity');
    }
    if (quantity == 0) {
      throw ArgumentError('Stock quantity cannot be zero: $quantity');
    }
    return quantity;
  }
  
  /// Validates order status transitions
  static bool isValidStatusTransition(String from, String to) {
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['packed', 'cancelled'],
      'packed': ['dispatched', 'cancelled'],
      'dispatched': ['out_for_delivery', 'cancelled'],
      'out_for_delivery': ['delivered', 'failed'],
      'delivered': [], // Final state
      'cancelled': [], // Final state
      'failed': ['out_for_delivery'], // Retry delivery
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }
}
