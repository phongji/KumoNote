import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/app_lock_settings.dart';
import '../../domain/repositories/app_lock_settings_repository.dart';

final class SecureAppLockSettingsRepository
    implements AppLockSettingsRepository {
  const SecureAppLockSettingsRepository({required this.storage});

  static const _enabledKey = 'kumo.security.app_lock.enabled';
  static const _delayKey = 'kumo.security.app_lock.delay';

  final FlutterSecureStorage storage;

  @override
  Future<AppLockSettings> read() async {
    try {
      final values = await storage.readAll();
      final isEnabled = values[_enabledKey] == 'true';
      final storedDelay = values[_delayKey];
      var delay = AppLockDelay.immediately;

      for (final candidate in AppLockDelay.values) {
        if (candidate.name == storedDelay) {
          delay = candidate;
          break;
        }
      }

      return AppLockSettings(isEnabled: isEnabled, delay: delay);
    } catch (_) {
      return const AppLockSettings.defaults();
    }
  }

  @override
  Future<void> save(AppLockSettings settings) async {
    await storage.write(key: _enabledKey, value: settings.isEnabled.toString());
    await storage.write(key: _delayKey, value: settings.delay.name);
  }
}
