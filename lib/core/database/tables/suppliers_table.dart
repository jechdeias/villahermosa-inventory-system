import 'package:drift/drift.dart';

@DataClassName('Supplier')
class Suppliers extends Table {
  // supplierCode/address1/address2/tin dropped v13 — zero reads in live
  // code; tradeName is the only supplier field displayed in the UI.
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get tradeName => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  // 'synced', not 'pending' like every other table — deliberately. Suppliers are
  // server-owned: nothing in the app creates or edits one locally (upsertSupplier
  // has zero callers; the admin UI only reads them for the product form's
  // dropdown), rows arrive only via the pull. If a local supplier editor is ever
  // added, its writes must set syncStatus = 'pending' explicitly or they will
  // never push.
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
