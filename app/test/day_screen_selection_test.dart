import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:slate/models/task.dart';
import 'package:slate/screens/day_screen.dart';
import 'package:slate/services/api_client.dart';
import 'package:slate/services/database_helper.dart';
import 'package:slate/services/sync_service.dart';
import 'package:slate/services/task_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SyncService syncService;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = await Directory.systemTemp.createTemp('slate_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
    final dbPath = p.join(tempDir.path, 'slate.db');
    if (File(dbPath).existsSync()) File(dbPath).deleteSync();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.database.then((db) => db.close());
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tasks');
    syncService = SyncService(ApiClient());
  });

  tearDown(() => syncService.dispose());

  final date = DateTime(2025, 1, 15);

  Future<void> seed() async {
    await TaskStorage.saveTask(Task(
        id: 'a', title: 'Alpha', date: date, sortOrder: 0));
    await TaskStorage.saveTask(Task(
        id: 'b', title: 'Bravo', date: date, sortOrder: 1));
  }

  // sqflite talks to a real file, so its futures need to run outside
  // the fake-async zone that testWidgets installs.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  Future<void> pumpDayScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DayScreen(
        date: date,
        syncService: syncService,
        tapAnywhereToAdd: false,
      ),
    ));
    await settle(tester);
  }

  testWidgets('long-press selects and bulk delete removes tasks',
      (tester) async {
    await tester.runAsync(seed);
    await pumpDayScreen(tester);

    expect(find.text('Alpha'), findsOneWidget);

    await tester.longPress(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 tasks?'), findsOneWidget);

    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Delete')));
    await settle(tester);

    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Bravo'), findsNothing);
    expect(await tester.runAsync(() => TaskStorage.loadTasks(date)), isEmpty);

    // Let the debounced sync timer fire so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1300));
    await settle(tester);
  });

  testWidgets('close button exits selection mode', (tester) async {
    await tester.runAsync(seed);
    await pumpDayScreen(tester);

    await tester.longPress(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
  });
}
