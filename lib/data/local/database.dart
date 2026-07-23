import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [ObligationRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// In-memory database for tests. Never opens a file, never touches disk.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> v2: direction (income/expense) added for the net-position
          // stat. Existing rows default to 'expense' — the product's
          // original assumption, and the only sign every obligation created
          // before this column existed was ever entered under.
          if (from < 2) {
            await m.addColumn(obligationRows, obligationRows.direction);
          }
          // v2 -> v3: snoozedUntil added so "Snooze" mutes an obligation
          // without touching its real expiryDate. Existing rows default to
          // null — nothing was snoozed before this column existed.
          if (from < 3) {
            await m.addColumn(obligationRows, obligationRows.snoozedUntil);
          }
        },
      );

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'meridian.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
