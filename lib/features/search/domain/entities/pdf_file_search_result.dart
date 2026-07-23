import '../../../library/domain/entities/notebook.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../../pdf/domain/entities/pdf_document_entity.dart';

final class PdfFileSearchResult {
  const PdfFileSearchResult({
    required this.document,
    required this.notebook,
    required this.pages,
  });

  final PdfDocumentEntity document;
  final Notebook notebook;
  final List<NotePage> pages;

  int get pageCount => pages.length;
}
