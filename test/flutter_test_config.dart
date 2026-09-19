import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts before every test file. Without this Flutter falls
/// back to the blocky "Ahem" test font, which distorts text metrics and makes
/// layout/overflow tests meaningless.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _load('Epilogue', 'assets/fonts/Epilogue-Variable.ttf');
  await _load('PlusJakartaSans', 'assets/fonts/PlusJakartaSans-Variable.ttf');
  await _load('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  await testMain();
}

Future<void> _load(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}
