import 'package:drift/drift.dart';

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
  
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {remoteId}, // remote_id should be unique when not null
  ];
}
