enum AppLockDelay {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const AppLockDelay(this.duration);

  final Duration duration;
}

final class AppLockSettings {
  const AppLockSettings({required this.isEnabled, required this.delay});

  const AppLockSettings.defaults()
    : isEnabled = false,
      delay = AppLockDelay.immediately;

  final bool isEnabled;
  final AppLockDelay delay;

  AppLockSettings copyWith({bool? isEnabled, AppLockDelay? delay}) {
    return AppLockSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      delay: delay ?? this.delay,
    );
  }
}
