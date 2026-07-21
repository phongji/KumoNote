import 'package:flutter/foundation.dart';

enum AppLogLevel { info, warning, error }

enum AppOperation {
  appStart,
  persistenceRead,
  persistenceWrite,
  importFile,
  exportFile,
  recovery,
  integrityCheck,
}

enum AppErrorCategory {
  none,
  validation,
  storage,
  permission,
  unsupportedFile,
  corruptedData,
  unexpected,
}

abstract interface class AppLogger {
  void record({
    required AppLogLevel level,
    required AppOperation operation,
    AppErrorCategory errorCategory = AppErrorCategory.none,
    String? entityId,
    Duration? duration,
    int? fileSizeBytes,
    int? schemaVersion,
  });
}

final class DebugAppLogger implements AppLogger {
  const DebugAppLogger();

  @override
  void record({
    required AppLogLevel level,
    required AppOperation operation,
    AppErrorCategory errorCategory = AppErrorCategory.none,
    String? entityId,
    Duration? duration,
    int? fileSizeBytes,
    int? schemaVersion,
  }) {
    if (!kDebugMode) {
      return;
    }

    final safeFields = <String, Object?>{
      'level': level.name,
      'operation': operation.name,
      'errorCategory': errorCategory.name,
      'entityId': entityId,
      'durationMs': duration?.inMilliseconds,
      'fileSizeBytes': fileSizeBytes,
      'schemaVersion': schemaVersion,
    }..removeWhere((key, value) => value == null);

    debugPrint('[Kumo] $safeFields');
  }
}
