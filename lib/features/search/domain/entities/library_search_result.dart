import '../../../library/domain/entities/notebook.dart';
import '../../../page/domain/entities/note_page.dart';

enum LibrarySearchResultType { typedText, pdfText, handwriting, imageText }

final class LibrarySearchResult {
  const LibrarySearchResult({
    required this.id,
    required this.type,
    required this.notebook,
    required this.page,
    required this.matchedText,
    required this.updatedAt,
  });

  final String id;
  final LibrarySearchResultType type;
  final Notebook notebook;
  final NotePage page;
  final String matchedText;
  final DateTime updatedAt;

  int get pageNumber => page.sortOrder ~/ 1000;
}
