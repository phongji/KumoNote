import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drawing/application/providers/drawing_providers.dart';
import '../../../image/application/providers/image_providers.dart';
import '../../../pdf/application/pdf_providers.dart';
import '../../../text/application/providers/text_providers.dart';
import '../services/notebook_pdf_export_service.dart';

final notebookPdfExportServiceProvider = Provider<NotebookPdfExportService>((
  ref,
) {
  return NotebookPdfExportService(
    inkRepository: ref.watch(inkRepositoryProvider),
    textRepository: ref.watch(textObjectRepositoryProvider),
    imageRepository: ref.watch(imageObjectRepositoryProvider),
    pdfRepository: ref.watch(pdfDocumentRepositoryProvider),
  );
});
