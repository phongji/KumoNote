import 'package:kumo_note/features/library/domain/entities/notebook.dart';

final class NotebookRecord {
  const NotebookRecord({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.sortOrder,
    required this.isFavorite,
    required this.coverColorValue,
    this.folderId,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? folderId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int version;
  final int sortOrder;
  final bool isFavorite;
  final int coverColorValue;

  factory NotebookRecord.fromDomain(Notebook notebook) {
    return NotebookRecord(
      id: notebook.id,
      title: notebook.title,
      folderId: notebook.folderId,
      createdAt: notebook.createdAt.toUtc().toIso8601String(),
      updatedAt: notebook.updatedAt.toUtc().toIso8601String(),
      deletedAt: notebook.deletedAt?.toUtc().toIso8601String(),
      version: notebook.version,
      sortOrder: notebook.sortOrder,
      isFavorite: notebook.isFavorite,
      coverColorValue: notebook.coverColorValue,
    );
  }

  factory NotebookRecord.fromJson(Map<String, Object?> json) {
    return NotebookRecord(
      id: json['id']! as String,
      title: json['title']! as String,
      folderId: json['folderId'] as String?,
      createdAt: json['createdAt']! as String,
      updatedAt: json['updatedAt']! as String,
      deletedAt: json['deletedAt'] as String?,
      version: json['version']! as int,
      sortOrder: json['sortOrder']! as int,
      isFavorite: json['isFavorite']! as bool,
      coverColorValue: json['coverColorValue']! as int,
    );
  }

  Notebook toDomain() {
    return Notebook(
      id: id,
      title: title,
      folderId: folderId,
      createdAt: DateTime.parse(createdAt).toLocal(),
      updatedAt: DateTime.parse(updatedAt).toLocal(),
      deletedAt: deletedAt == null
          ? null
          : DateTime.parse(deletedAt!).toLocal(),
      version: version,
      sortOrder: sortOrder,
      isFavorite: isFavorite,
      coverColorValue: coverColorValue,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'folderId': folderId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'version': version,
      'sortOrder': sortOrder,
      'isFavorite': isFavorite,
      'coverColorValue': coverColorValue,
    };
  }
}
