import 'package:drift/drift.dart';

@DataClassName('StockMovement')
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  
  IntColumn get productId => integer()();
  IntColumn get quantityChange => integer()(); // + for stock in, - for stock out
  
  TextColumn get reason => text()(); // sale | delivery | restock | adjustment | damage | return
  
  // Reference to what triggered this movement (optional)
  IntColumn get referenceId => integer().nullable()(); // order_id, delivery_id, etc.
  TextColumn get referenceType => text().nullable()(); // 'order', 'delivery', 'manual'
  
  IntColumn get createdBy => integer()(); // user_id who performed this action
  
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // Foreign keys
  @override
  List<Set<Column>> get uniqueKeys => [
    {remoteId}, // remote_id should be unique when not null
  ];
  
  @override
  List<ForeignKey> get foreignKeys => [
    ForeignKey(
      targetTable: Products,
      targetColumns: [id],
      childColumns: [productId],
      onUpdate: KeyAction.restrict,
      onDelete: KeyAction.restrict,
    ),
    ForeignKey(
      targetTable: Users,
      targetColumns: [id],
      childColumns: [createdBy],
      onUpdate: KeyAction.restrict,
      onDelete: KeyAction.restrict,
    ),
  ];
}
