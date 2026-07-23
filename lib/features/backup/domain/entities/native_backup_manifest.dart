final class NativeBackupManifest {
  const NativeBackupManifest({
    required this.format,
    required this.schemaVersion,
    required this.backupId,
    required this.createdAt,
    required this.notebookId,
    required this.notebookTitle,
    required this.fileChecksums,
  });

  static const currentFormat = 'kumo-notes-native-backup';
  static const currentSchemaVersion = 1;

  final String format;
  final int schemaVersion;
  final String backupId;
  final DateTime createdAt;
  final String notebookId;
  final String notebookTitle;
  final Map<String, String> fileChecksums;

  bool get isSupported {
    return format == currentFormat &&
        schemaVersion > 0 &&
        schemaVersion <= currentSchemaVersion;
  }

  factory NativeBackupManifest.fromJson(Map<String, Object?> json) {
    final rawChecksums = json['fileChecksums'];

    if (rawChecksums is! Map) {
      throw const FormatException(
        'Backup manifest fileChecksums must be an object.',
      );
    }

    return NativeBackupManifest(
      format: json['format']! as String,
      schemaVersion: (json['schemaVersion']! as num).toInt(),
      backupId: json['backupId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      notebookId: json['notebookId']! as String,
      notebookTitle: json['notebookTitle']! as String,
      fileChecksums: rawChecksums.map<String, String>((key, value) {
        return MapEntry(key as String, value as String);
      }),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'format': format,
      'schemaVersion': schemaVersion,
      'backupId': backupId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'notebookId': notebookId,
      'notebookTitle': notebookTitle,
      'fileChecksums': fileChecksums,
    };
  }
}
