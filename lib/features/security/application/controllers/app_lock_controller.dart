import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_lock_settings.dart';
import '../providers/security_providers.dart';
import '../services/device_authentication_service.dart';
import '../state/app_lock_state.dart';

final appLockControllerProvider =
    AsyncNotifierProvider<AppLockController, AppLockState>(
      AppLockController.new,
    );

final class AppLockController extends AsyncNotifier<AppLockState> {
  @override
  Future<AppLockState> build() async {
    final settings = await ref.read(appLockSettingsRepositoryProvider).read();
    final availability = await ref
        .read(deviceAuthenticationServiceProvider)
        .checkAvailability();

    return AppLockState(
      settings: settings,
      availability: availability,
      isLocked:
          settings.isEnabled &&
          availability == DeviceAuthenticationAvailability.available,
      isAuthenticating: false,
    );
  }

  Future<DeviceAuthenticationResult> enable({required String reason}) async {
    final current = state.requireValue;

    if (!current.canUseAppLock) {
      return DeviceAuthenticationResult.unavailable;
    }

    final result = await _authenticate(reason: reason);

    if (result != DeviceAuthenticationResult.authenticated) {
      return result;
    }

    final settings = current.settings.copyWith(isEnabled: true);
    await ref.read(appLockSettingsRepositoryProvider).save(settings);

    state = AsyncData(
      state.requireValue.copyWith(
        settings: settings,
        isLocked: false,
        isAuthenticating: false,
      ),
    );

    return result;
  }

  Future<DeviceAuthenticationResult> disable({required String reason}) async {
    final current = state.requireValue;

    if (!current.settings.isEnabled) {
      return DeviceAuthenticationResult.authenticated;
    }

    final result = await _authenticate(reason: reason);

    if (result != DeviceAuthenticationResult.authenticated) {
      return result;
    }

    final disabledSettings = current.settings.copyWith(isEnabled: false);
    await ref.read(appLockSettingsRepositoryProvider).save(disabledSettings);

    state = AsyncData(
      state.requireValue.copyWith(
        settings: disabledSettings,
        isLocked: false,
        isAuthenticating: false,
      ),
    );

    return result;
  }

  Future<void> setDelay(AppLockDelay delay) async {
    final current = state.requireValue;
    final settings = current.settings.copyWith(delay: delay);

    await ref.read(appLockSettingsRepositoryProvider).save(settings);
    state = AsyncData(current.copyWith(settings: settings));
  }

  void lockIfDue(DateTime backgroundedAt) {
    final current = state.asData?.value;

    if (current == null ||
        !current.settings.isEnabled ||
        !current.canUseAppLock) {
      return;
    }

    final elapsed = DateTime.now().difference(backgroundedAt);

    if (elapsed >= current.settings.delay.duration) {
      state = AsyncData(current.copyWith(isLocked: true));
    }
  }

  void lockNow() {
    final current = state.asData?.value;

    if (current == null ||
        !current.settings.isEnabled ||
        !current.canUseAppLock) {
      return;
    }

    state = AsyncData(current.copyWith(isLocked: true));
  }

  Future<DeviceAuthenticationResult> unlock({required String reason}) async {
    final current = state.requireValue;

    if (!current.isLocked) {
      return DeviceAuthenticationResult.authenticated;
    }

    final result = await _authenticate(reason: reason);

    if (result == DeviceAuthenticationResult.authenticated) {
      state = AsyncData(
        state.requireValue.copyWith(isLocked: false, isAuthenticating: false),
      );
    }

    return result;
  }

  Future<DeviceAuthenticationResult> _authenticate({
    required String reason,
  }) async {
    final current = state.requireValue;

    if (current.isAuthenticating) {
      return DeviceAuthenticationResult.cancelled;
    }

    state = AsyncData(current.copyWith(isAuthenticating: true));

    final result = await ref
        .read(deviceAuthenticationServiceProvider)
        .authenticate(reason: reason);

    final latest = state.requireValue;
    state = AsyncData(latest.copyWith(isAuthenticating: false));

    return result;
  }
}
