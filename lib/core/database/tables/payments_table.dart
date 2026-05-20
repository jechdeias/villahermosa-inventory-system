import 'package:drift/drift.dart';
import 'orders_table.dart';
import 'users_table.dart';

@DataClassName('Payment')
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get paymentId => text()();
  IntColumn get orderId => integer().references(Orders, #id)();
  TextColumn get orderCode => text()();
  TextColumn get storeName => text()();
  IntColumn get salesRepId => integer().references(Users, #id)();
  TextColumn get salesRepName => text()();
  RealColumn get orderAmount => real()();
  RealColumn get amountPaid => real().withDefault(const Constant(0))();
  RealColumn get balance => real()();
  TextColumn get paymentMethod => text().nullable()();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}
