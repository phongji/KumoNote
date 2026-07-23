import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drawing/application/providers/drawing_providers.dart';
import '../../../image/application/providers/image_providers.dart';
import '../../../library/application/providers/library_providers.dart';
import '../../../page/application/providers/page_providers.dart';
import '../../../pdf/application/pdf_providers.dart';
import '../../../text/application/providers/text_providers.dart';
import '../services/native_backup_service.dart';
import '../services/native_backup_inspector.dart';
import '../services/native_restore_service.dart';

final nativeBackupServiceProvider = Provider<NativeBackupService>((ref) {
  return NativeBackupService(
    notebookRepository: ref.watch(notebookRepositoryProvider),
    pageRepository: ref.watch(pageRepositoryProvider),
    inkRepository: ref.watch(inkRepositoryProvider),
    textRepository: ref.watch(textObjectRepositoryProvider),
    imageRepository: ref.watch(imageObjectRepositoryProvider),
    pdfRepository: ref.watch(pdfDocumentRepositoryProvider),
  );
});

final nativeBackupInspectorProvider = Provider<NativeBackupInspector>((ref) {
  return const NativeBackupInspector();
});

final nativeRestoreServiceProvider = Provider<NativeRestoreService>((ref) {
  return NativeRestoreService(
    notebookRepository: ref.watch(notebookRepositoryProvider),
    pageRepository: ref.watch(pageRepositoryProvider),
    inkRepository: ref.watch(inkRepositoryProvider),
    textRepository: ref.watch(textObjectRepositoryProvider),
    imageRepository: ref.watch(imageObjectRepositoryProvider),
    pdfRepository: ref.watch(pdfDocumentRepositoryProvider),
  );
});
