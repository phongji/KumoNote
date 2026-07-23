import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../drawing/application/controllers/drawing_controller.dart';
import '../../../drawing/application/state/drawing_state.dart';
import '../../../drawing/presentation/screens/page_editor_screen.dart';
import '../../../drawing/presentation/widgets/scene_object_layer.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../application/pdf_providers.dart';
import '../../domain/entities/pdf_document_entity.dart';

final class PdfDocumentScreen extends ConsumerStatefulWidget {
  const PdfDocumentScreen({
    required this.document,
    required this.pages,
    super.key,
  });

  final PdfDocumentEntity document;
  final List<NotePage> pages;

  @override
  ConsumerState<PdfDocumentScreen> createState() {
    return _PdfDocumentScreenState();
  }
}

final class _PdfDocumentScreenState extends ConsumerState<PdfDocumentScreen> {
  Uint8List? _cachedBytes;
  PdfDocumentRefData? _documentRef;

  List<NotePage> get _orderedPages {
    final pages = [...widget.pages];

    pages.sort((first, second) {
      return (first.pdfPageNumber ?? 0).compareTo(second.pdfPageNumber ?? 0);
    });

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final bytes = ref.watch(
      pdfDocumentBytesProvider(widget.document.storageKey),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              strings.pdfPageCount(widget.document.pageCount),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: bytes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _PdfLoadError(),
        data: (value) {
          if (value == null || value.isEmpty) {
            return const _PdfLoadError();
          }

          return PdfDocumentViewBuilder(
            documentRef: _referenceFor(value),
            builder: (context, document) {
              if (document == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return _ContinuousPdfPages(
                document: document,
                pages: _orderedPages,
              );
            },
          );
        },
      ),
    );
  }

  PdfDocumentRefData _referenceFor(Uint8List bytes) {
    if (!identical(_cachedBytes, bytes) || _documentRef == null) {
      _cachedBytes = bytes;
      _documentRef = PdfDocumentRefData(
        bytes,
        sourceName: widget.document.fileName,
        useProgressiveLoading: false,
        allowDataOwnershipTransfer: false,
      );
    }

    return _documentRef!;
  }
}

final class _ContinuousPdfPages extends StatelessWidget {
  const _ContinuousPdfPages({required this.document, required this.pages});

  final PdfDocument document;
  final List<NotePage> pages;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = (constraints.maxWidth - 32)
              .clamp(280.0, 900.0)
              .toDouble();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            scrollCacheExtent: const ScrollCacheExtent.pixels(900),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final notePage = pages[index];
              final pageNumber = notePage.pdfPageNumber ?? index + 1;
              final pageHeight = pageWidth * notePage.height / notePage.width;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.12),
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(3),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) {
                                  return PageEditorScreen(
                                    page: notePage,
                                    pageNumber: pageNumber,
                                  );
                                },
                              ),
                            );
                          },
                          child: SizedBox(
                            width: pageWidth,
                            height: pageHeight,
                            child: _PdfPagePreview(
                              document: document,
                              notePage: notePage,
                              pageNumber: pageNumber,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '$pageNumber',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final class _PdfPagePreview extends ConsumerWidget {
  const _PdfPagePreview({
    required this.document,
    required this.notePage,
    required this.pageNumber,
  });

  final PdfDocument document;
  final NotePage notePage;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawing = ref.watch(drawingControllerProvider(notePage.id));

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PdfPageView(
            document: document,
            pageNumber: pageNumber,
            alignment: Alignment.center,
          ),
          drawing.maybeWhen(
            data: (state) {
              return SceneObjectLayer(
                pageId: notePage.id,
                strokes: state.strokes,
                interactionMode: CanvasInteractionMode.navigation,
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

final class _PdfLoadError extends StatelessWidget {
  const _PdfLoadError();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 36,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 10),
          Text(strings.pdfOpenFailed),
        ],
      ),
    );
  }
}
