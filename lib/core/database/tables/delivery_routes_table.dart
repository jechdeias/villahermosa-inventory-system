import 'package:drift/drift.dart';

/// Represents a sales/delivery route (e.g. "Route 1 - Centro") that an admin
/// configures and assigns to a sales rep with a delivery-day schedule.
@DataClassName('DeliveryRoute')
class DeliveryRoutes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text().unique()();

  TextColumn get routeName => text()();

  TextColumn get municipality => text()();

  TextColumn get assignedRepName => text().nullable()();

  /// Comma-joined delivery days, e.g. "Mon,Wed,Fri".
  TextColumn get deliveryDays => text()();

  IntColumn get customerCount => integer().withDefault(const Constant(0))();

  /// 'active' | 'on_hold' | 'inactive'
  TextColumn get status => text().withDefault(const Constant('active'))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
