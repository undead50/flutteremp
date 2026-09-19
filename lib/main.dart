import 'package:relay/bootstrap.dart';

/// Single entry point for every environment. Select one at build/run time:
///
///     flutter run --dart-define-from-file=config/dev.json
Future<void> main() => bootstrap();
