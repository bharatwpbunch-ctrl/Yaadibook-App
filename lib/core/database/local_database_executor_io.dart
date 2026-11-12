import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

Future<QueryExecutor?> openPlatformDriftExecutor({
  bool inMemory = false,
}) async {
  try {
    if (inMemory) {
      return NativeDatabase.memory();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/yaadibook_offline_v1.sqlite');
    return NativeDatabase(file);
  } catch (e) {
    AppLogger.warning(
      'Native SQLite executor unavailable in current runtime ($e); using in-memory store fallback.',
    );
    return null;
  }
}
