import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../application/pdf_providers.dart';

final class PdfPageBackground extends ConsumerWidget {
  const PdfPageBackground({
    required this.documentId,
    required this.pageNumber,
    super.key,
  });

  final String documentId;
  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(pdfDocumentProvider(documentId));

    return document.when(
      loading: () => const _QuietLoadingIndicator(),
      error: (_, _) => const _PdfBackgroundError(),
      data: (item) {
        if (item == null || pageNumber < 1 || pageNumber > item.pageCount) {
          return const _PdfBackgroundError();
        }

        return _PdfPageFromStorage(
          storageKey: item.storageKey,
          sourceName: item.fileName,
          pageNumber: pageNumber,
        );
      },
    );
  }
}

final class _PdfPageFromStorage extends ConsumerStatefulWidget {
  const _PdfPageFromStorage({
    required this.storageKey,
    required this.sourceName,
    required this.pageNumber,
  });

  final String storageKey;
  final String sourceName;
  final int pageNumber;

  @override
  ConsumerState<_PdfPageFromStorage> createState() {
    return _PdfPageFromStorageState();
  }
}

final class _PdfPageFromStorageState
    extends ConsumerState<_PdfPageFromStorage> {
  Uint8List? _cachedBytes;
  PdfDocumentRefData? _documentRef;

  @override
  void didUpdateWidget(_PdfPageFromStorage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.storageKey != widget.storageKey) {
      _cachedBytes = null;
      _documentRef = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = ref.watch(pdfDocumentBytesProvider(widget.storageKey));

    return bytes.when(
      loading: () => const _QuietLoadingIndicator(),
      error: (_, _) => const _PdfBackgroundError(),
      data: (value) {
        if (value == null || value.isEmpty) {
          return const _PdfBackgroundError();
        }

        final documentRef = _referenceFor(value);

        return IgnorePointer(
          child: PdfDocumentViewBuilder(
            documentRef: documentRef,
            builder: (context, document) {
              if (document == null) {
                return const _QuietLoadingIndicator();
              }

              if (widget.pageNumber > document.pages.length) {
                return const _PdfBackgroundError();
              }

              return PdfPageView(
                document: document,
                pageNumber: widget.pageNumber,
                alignment: Alignment.center,
              );
            },
          ),
        );
      },
    );
  }

  PdfDocumentRefData _referenceFor(Uint8List bytes) {
    if (!identical(_cachedBytes, bytes) || _documentRef == null) {
      _cachedBytes = bytes;
      _documentRef = PdfDocumentRefData(
        bytes,
        sourceName: widget.sourceName,
        useProgressiveLoading: false,
        allowDataOwnershipTransfer: false,
      );
    }

    return _documentRef!;
  }
}

final class _QuietLoadingIndicator extends StatelessWidget {
  const _QuietLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.outline,
        ),
      ),
    );
  }
}

final class _PdfBackgroundError extends StatelessWidget {
  const _PdfBackgroundError();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Icon(
        Icons.picture_as_pdf_outlined,
        size: 28,
        color: colorScheme.outline.withValues(alpha: 0.55),
      ),
    );
  }
}
