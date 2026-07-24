import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/app_lock_controller.dart';
import '../../application/services/device_authentication_service.dart';

final class PrivacyCover extends ConsumerStatefulWidget {
  const PrivacyCover({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrivacyCover> createState() => _PrivacyCoverState();
}

final class _PrivacyCoverState extends ConsumerState<PrivacyCover>
    with WidgetsBindingObserver {
  bool _isLifecycleCovered = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;

      if (backgroundedAt != null) {
        ref.read(appLockControllerProvider.notifier).lockIfDue(backgroundedAt);
      }

      setState(() {
        _backgroundedAt = null;
        _isLifecycleCovered = false;
      });
      return;
    }

    setState(() {
      _backgroundedAt ??= DateTime.now();
      _isLifecycleCovered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLock = ref.watch(appLockControllerProvider);
    final lockState = appLock.asData?.value;
    final isLocked = lockState?.isLocked ?? false;
    final shouldHideContent =
        _isLifecycleCovered || appLock.isLoading || appLock.hasError;

    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !shouldHideContent && !isLocked,
          child: widget.child,
        ),
        if (shouldHideContent)
          const Positioned.fill(child: _PrivateContentCover())
        else if (isLocked)
          Positioned.fill(
            child: _AppLockedCover(
              isAuthenticating: lockState?.isAuthenticating ?? false,
              onUnlock: _requestUnlock,
            ),
          ),
      ],
    );
  }

  Future<void> _requestUnlock() async {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final result = await ref
        .read(appLockControllerProvider.notifier)
        .unlock(
          reason: isThai
              ? 'ยืนยันตัวตนเพื่อเปิด Kumo Notes'
              : 'Authenticate to open Kumo Notes.',
        );

    if (!mounted ||
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
                ? 'ยังยืนยันตัวตนไม่ได้ กรุณาลองอีกครั้ง'
                : 'Authentication was not available. Please try again.',
          ),
        ),
      );
  }
}

final class _PrivateContentCover extends StatelessWidget {
  const _PrivateContentCover();

  @override
  Widget build(BuildContext context) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    return _SecuritySurface(
      icon: Icons.cloud_outlined,
      message: isThai ? 'เนื้อหาของคุณถูกซ่อนไว้' : 'Your notes are hidden.',
    );
  }
}

final class _AppLockedCover extends StatelessWidget {
  const _AppLockedCover({
    required this.isAuthenticating,
    required this.onUnlock,
  });

  final bool isAuthenticating;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    return _SecuritySurface(
      icon: Icons.lock_outline_rounded,
      message: isThai ? 'Kumo Notes ถูกล็อก' : 'Kumo Notes is locked.',
      action: FilledButton.icon(
        onPressed: isAuthenticating ? null : onUnlock,
        icon: isAuthenticating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.fingerprint_rounded),
        label: Text(
          isAuthenticating
              ? (isThai ? 'กำลังยืนยัน…' : 'Authenticating…')
              : (isThai ? 'ปลดล็อก' : 'Unlock'),
        ),
      ),
    );
  }
}

final class _SecuritySurface extends StatelessWidget {
  const _SecuritySurface({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlockSemantics(
      child: Material(
        color: colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: colorScheme.primary),
              const SizedBox(height: 14),
              Text('Kumo Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 22), action!],
            ],
          ),
        ),
      ),
    );
  }
}
