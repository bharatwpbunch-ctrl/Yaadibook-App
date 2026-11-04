import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// Global test configuration executed before any test in test/ directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
