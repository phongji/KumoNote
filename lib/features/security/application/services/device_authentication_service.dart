import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum DeviceAuthenticationAvailability {
  available,
  unavailable,
  unsupportedPlatform,
}

enum DeviceAuthenticationResult {
  authenticated,
  cancelled,
  unavailable,
  failed,
}

final class DeviceAuthenticationService {
  DeviceAuthenticationService({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  Future<DeviceAuthenticationAvailability> checkAvailability() async {
    if (!_isSupportedPlatform) {
      return DeviceAuthenticationAvailability.unsupportedPlatform;
    }

    try {
      final isSupported = await _localAuthentication.isDeviceSupported();

      return isSupported
          ? DeviceAuthenticationAvailability.available
          : DeviceAuthenticationAvailability.unavailable;
    } catch (_) {
      return DeviceAuthenticationAvailability.unavailable;
    }
  }

  Future<DeviceAuthenticationResult> authenticate({
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Authentication reason must not be empty.',
      );
    }

    final availability = await checkAvailability();

    if (availability != DeviceAuthenticationAvailability.available) {
      return DeviceAuthenticationResult.unavailable;
    }

    try {
      final didAuthenticate = await _localAuthentication.authenticate(
        localizedReason: reason.trim(),
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      return didAuthenticate
          ? DeviceAuthenticationResult.authenticated
          : DeviceAuthenticationResult.cancelled;
    } catch (_) {
      return DeviceAuthenticationResult.failed;
    }
  }

  Future<void> cancelAuthentication() async {
    if (!_isSupportedPlatform) {
      return;
    }

    try {
      await _localAuthentication.stopAuthentication();
    } catch (_) {
      // The platform may have already closed the authentication prompt.
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.fuchsia || TargetPlatform.linux => false,
    };
  }
}
