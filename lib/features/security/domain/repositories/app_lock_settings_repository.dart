import '../entities/app_lock_settings.dart';

abstract interface class AppLockSettingsRepository {
  Future<AppLockSettings> read();

  Future<void> save(AppLockSettings settings);
}
