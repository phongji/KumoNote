import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/app_lock_controller.dart';
import '../../application/services/device_authentication_service.dart';
import '../../domain/entities/app_lock_settings.dart';

final class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final appLock = ref.watch(appLockControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'ความเป็นส่วนตัว' : 'Privacy & security'),
      ),
      body: appLock.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: IconButton.filledTonal(
            tooltip: isThai ? 'ลองอีกครั้ง' : 'Try again',
            onPressed: () {
              ref.invalidate(appLockControllerProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SettingsSection(
                title: isThai ? 'การล็อกแอป' : 'App lock',
                children: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.lock_outline_rounded),
                    title: Text(isThai ? 'ใช้ App Lock' : 'Use App Lock'),
                    subtitle: Text(
                      _appLockDescription(
                        isThai: isThai,
                        isAvailable: state.canUseAppLock,
                      ),
                    ),
                    value: state.settings.isEnabled && state.canUseAppLock,
                    onChanged: !state.canUseAppLock || state.isAuthenticating
                        ? null
                        : (enabled) {
                            _setAppLockEnabled(
                              context: context,
                              ref: ref,
                              enabled: enabled,
                            );
                          },
                  ),
                  if (state.settings.isEnabled && state.canUseAppLock)
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(
                        isThai ? 'ล็อกเมื่อออกจากแอป' : 'Lock after leaving',
                      ),
                      trailing: DropdownButton<AppLockDelay>(
                        value: state.settings.delay,
                        underline: const SizedBox.shrink(),
                        onChanged: state.isAuthenticating
                            ? null
                            : (delay) {
                                if (delay == null) {
                                  return;
                                }

                                ref
                                    .read(appLockControllerProvider.notifier)
                                    .setDelay(delay);
                              },
                        items: [
                          for (final delay in AppLockDelay.values)
                            DropdownMenuItem(
                              value: delay,
                              child: Text(
                                _delayLabel(delay: delay, isThai: isThai),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (state.isAuthenticating)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: isThai ? 'การปกป้องหน้าจอ' : 'Screen protection',
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(
                      isThai
                          ? 'ซ่อนเนื้อหาเมื่อออกจากแอป'
                          : 'Hide content when leaving the app',
                    ),
                    subtitle: Text(
                      isThai
                          ? 'เปิดใช้งานอยู่เสมอ เพื่อป้องกันภาพตัวอย่างสมุดในหน้าสลับแอป'
                          : 'Always on to protect notebook previews in the app switcher.',
                    ),
                    trailing: const Icon(Icons.check_circle_outline_rounded),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setAppLockEnabled({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
  }) async {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final controller = ref.read(appLockControllerProvider.notifier);
    final result = enabled
        ? await controller.enable(
            reason: isThai
                ? 'ยืนยันตัวตนเพื่อเปิด App Lock'
                : 'Authenticate to enable App Lock.',
          )
        : await controller.disable(
            reason: isThai
                ? 'ยืนยันตัวตนเพื่อปิด App Lock'
                : 'Authenticate to disable App Lock.',
          );

    if (!context.mounted ||
        result == DeviceAuthenticationResult.authenticated ||
        result == DeviceAuthenticationResult.cancelled) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isThai
                ? 'ยังเปลี่ยนการตั้งค่า App Lock ไม่ได้'
                : 'The App Lock setting could not be changed.',
          ),
        ),
      );
  }

  String _appLockDescription({
    required bool isThai,
    required bool isAvailable,
  }) {
    if (!isAvailable) {
      return isThai
          ? 'ใช้การยืนยันตัวตนของเครื่อง รองรับเมื่อเปิดแอปบน Android หรือ iPhone'
          : 'Uses device authentication when running on Android or iPhone.';
    }

    return isThai
        ? 'ใช้ลายนิ้วมือ ใบหน้า หรือรหัสล็อกเครื่อง'
        : 'Use fingerprint, face, or the device passcode.';
  }

  String _delayLabel({required AppLockDelay delay, required bool isThai}) {
    return switch (delay) {
      AppLockDelay.immediately => isThai ? 'ทันที' : 'Immediately',
      AppLockDelay.oneMinute => isThai ? '1 นาที' : '1 minute',
      AppLockDelay.fiveMinutes => isThai ? '5 นาที' : '5 minutes',
    };
  }
}

final class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colorScheme.primary),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
