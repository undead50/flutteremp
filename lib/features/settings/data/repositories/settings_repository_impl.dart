import 'package:relay/core/error/result.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/guarded_call.dart';
import 'package:relay/features/settings/data/datasources/settings_remote_data_source.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';
import 'package:relay/features/settings/domain/repositories/settings_repositories.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SettingsRemoteDataSource remote, required AppLogger logger})
    : _remote = remote,
      _logger = logger;

  final SettingsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<SignOffProxy?>> getSignOffProxy() =>
      guardedCall(_remote.fetchSignOffProxy, _logger);
}

/// Every write in the app is currently online-only (a failed approval is shown
/// to the user rather than queued), so there is nothing to deliver. This keeps
/// the "Synchronize Offline Outbox" control honest and gives an offline queue a
/// place to plug in later.
final class NoopOutboxRepository implements OutboxRepository {
  const NoopOutboxRepository();

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<Result<int>> sync() async => const Result<int>.success(0);
}
