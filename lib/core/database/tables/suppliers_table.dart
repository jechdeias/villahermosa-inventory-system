import 'package:drift/drift.dart';

@DataClassName('Supplier')
class Suppliers extends Table {
  // supplierCode/address1/address2/tin dropped v13 — zero reads in live
  // code; tradeName is the only supplier field displayed in the UI.
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get tradeName => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
