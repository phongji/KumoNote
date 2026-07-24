import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repositories/secure_app_lock_settings_repository.dart';
import '../../domain/repositories/app_lock_settings_repository.dart';
import '../services/device_authentication_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final appLockSettingsRepositoryProvider = Provider<AppLockSettingsRepository>((
  ref,
) {
  return SecureAppLockSettingsRepository(
    storage: ref.watch(secureStorageProvider),
  );
});

final deviceAuthenticationServiceProvider =
    Provider<DeviceAuthenticationService>((ref) {
      return DeviceAuthenticationService();
    });
