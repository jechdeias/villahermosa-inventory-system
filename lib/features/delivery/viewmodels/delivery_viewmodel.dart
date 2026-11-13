/// Delivery View Model
///
/// State management for the delivery role's confirmation screen.
/// Confirmation methods:
///   - Manual button  → looks up the linked order and marks it delivered
///   - Code entry     → customer gives the rep a 6-digit code the rep generated
///   - QR (routed to SalesScanScreen — no logic needed here)
library;
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/constants/order_status.dart';
import '../../../core/database/app_database.dart';
import '../../sales/services/delivery_confirmation.dart';

class DeliveryViewModel extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  String? _generatedDeliveryCode;
  bool _isCodeValid = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get generatedDeliveryCode => _generatedDeliveryCode;
  bool get isCodeValid => _isCodeValid;

  // ── Manual confirmation ────────────────────────────────────────────────────

  /// Marks the order [orderUuid] as delivered.
  /// [orderUuid] is the order's UUID (passed from route_screen via
  /// DeliveryConfirmationScreen.deliveryId). The order is looked up
  /// directly — NOT via the deliveries table, which nothing in the app
  /// ever writes to (it is sync-pull-only), so a lookup through it
  /// always came back empty. Re-reading the order here also means a
  /// stale screen can't deliver an order that has since changed —
  /// same rules as markOrderDelivered's other callers (dashboard
  /// button, QR scan). Works offline (Drift write) and queues a
  /// background sync.
  Future<void> confirmDeliveryByButton(String orderUuid) async {
    _setLoading(true);
    try {
      final db = AuthService.instance.database;
      final order = await _getConfirmableOrder(db, orderUuid);
      if (order == null) return; // _getConfirmableOrder already set the error
      await markOrderDelivered(db, order, method: deliveryMethodManual);
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Re-reads the order and checks it is still confirmable.
  /// Returns null (with [error] set) if missing or not out for delivery.
  Future<Order?> _getConfirmableOrder(AppDatabase db, String orderUuid) async {
    final order = await db.getOrderById(orderUuid);
    if (order == null) {
      _setError('Order not found.');
      return null;
    }
    if (order.status != OrderStatus.outForDelivery) {
      _setError(order.status == OrderStatus.delivered || order.status == OrderStatus.completed
          ? 'This order has already been delivered.'
          : 'This order is not out for delivery.');
      return null;
    }
    return order;
  }

  // ── Code-based confirmation ────────────────────────────────────────────────

  /// Generates a random 6-digit code and stores it in-memory.
  /// The rep reads it aloud or shows it; the customer reads it back.
  Future<void> generateDeliveryCode(String deliveryId) async {
    _setLoading(true);
    try {
      final code = (Random.secure().nextInt(900000) + 100000).toString();
      _generatedDeliveryCode = code;
      _isCodeValid = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Checks whether [confirmationCode] matches the generated code.
  /// Updates [isCodeValid] so the UI can give instant feedback.
  Future<void> validateDeliveryCode(String deliveryId, String confirmationCode) async {
    _isCodeValid = _generatedDeliveryCode != null &&
        confirmationCode.trim() == _generatedDeliveryCode;
    notifyListeners();
  }

  /// Validates the code then marks the order delivered if it matches.
  /// [orderUuid] is the order's UUID — same semantics as [confirmDeliveryByButton].
  Future<void> confirmDeliveryByCode(String orderUuid, String confirmationCode) async {
    if (_generatedDeliveryCode == null ||
        confirmationCode.trim() != _generatedDeliveryCode) {
      _setError('Incorrect code. Please check and try again.');
      return;
    }
    _setLoading(true);
    try {
      final db = AuthService.instance.database;
      final order = await _getConfirmableOrder(db, orderUuid);
      if (order == null) return; // _getConfirmableOrder already set the error
      await markOrderDelivered(db, order, method: deliveryMethodManual);
      _generatedDeliveryCode = null; // invalidate after use
      _isCodeValid = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Route / delivery list stubs (not used by confirmation screen) ──────────

  Future<void> loadRoutes() async {}
  Future<void> createRoute(Map<String, dynamic> routeData) async {}
  Future<void> updateRoute(String routeId, Map<String, dynamic> routeData) async {}
  Future<void> selectRoute(String routeId) async {}
  Future<void> loadDeliveries(String routeId) async {}
  Future<void> startDelivery(String deliveryId) async {}
  Future<void> completeDelivery(String deliveryId, Map<String, dynamic> confirmationData) async {}
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {}
  Future<void> updateLocation(Map<String, dynamic> locationData) async {}
  Future<void> getDeliveryConfirmationStatus(String deliveryId) async {}

  // ── Helpers ────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Only clear the error when a new operation STARTS. _setLoading(false)
    // runs in `finally` blocks after _setError — clearing here too would wipe
    // the error before the screen reads it and make failures look like
    // successes.
    if (loading) _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
}
