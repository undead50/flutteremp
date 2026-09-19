import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/domain/repositories/settings_repositories.dart';

/// Persists new preferences.
///
/// Rule: at least one workspace module must stay active, otherwise the primary
/// deck would have nothing to show and no way back.
final class UpdatePreferences {
  const UpdatePreferences(this._repository);

  final PreferencesRepository _repository;

  Future<Result<UserPreferences>> call(UserPreferences next) async {
    if (next.activeModules.isEmpty) {
      return const Result<UserPreferences>.failure(
        ValidationFailure('Keep at least one module active.'),
      );
    }
    await _repository.save(next);
    return Result<UserPreferences>.success(next);
  }
}

final class GetSignOffProxy {
  const GetSignOffProxy(this._repository);

  final SettingsRepository _repository;

  Future<Result<SignOffProxy?>> call() => _repository.getSignOffProxy();
}

final class SyncOutbox {
  const SyncOutbox(this._repository);

  final OutboxRepository _repository;

  Future<Result<int>> call() => _repository.sync();
}

final class GetOutboxCount {
  const GetOutboxCount(this._repository);

  final OutboxRepository _repository;

  Future<int> call() => _repository.pendingCount();
}
