import '../../domain/entities/app_lock_settings.dart';
import '../services/device_authentication_service.dart';

final class AppLockState {
  const AppLockState({
    required this.settings,
    required this.availability,
    required this.isLocked,
    required this.isAuthenticating,
  });

  final AppLockSettings settings;
  final DeviceAuthenticationAvailability availability;
  final bool isLocked;
  final bool isAuthenticating;

  bool get canUseAppLock {
    return availability == DeviceAuthenticationAvailability.available;
  }

  AppLockState copyWith({
    AppLockSettings? settings,
    DeviceAuthenticationAvailability? availability,
    bool? isLocked,
    bool? isAuthenticating,
  }) {
    return AppLockState(
      settings: settings ?? this.settings,
      availability: availability ?? this.availability,
      isLocked: isLocked ?? this.isLocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    );
  }
}
