import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pdf/application/pdf_providers.dart';
import '../../application/controllers/page_controller.dart' as page_app;
import '../../application/providers/page_providers.dart';
import '../widgets/notebook_contents.dart';
import '../widgets/page_setup_dialog.dart';
import 'page_trash_screen.dart';

final class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({
    required this.notebookId,
    required this.notebookName,
    super.key,
  });

  final String notebookId;
  final String notebookName;

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

final class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  bool _isImportingPdf = false;

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(activePageListProvider(widget.notebookId));
    final documents = ref.watch(pdfDocumentListProvider(widget.notebookId));
    final controller = ref.read(
      page_app.pageControllerProvider(widget.notebookId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebookName),
        actions: [
          IconButton(
            tooltip: 'Import PDF',
            onPressed: _isImportingPdf
                ? null
                : () async {
                    await _importPdf(controller);
                  },
            icon: _isImportingPdf
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Trash',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return PageTrashScreen(notebookId: widget.notebookId);
                  },
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Create page',
            onPressed: () async {
              await _createPageWithSetup(
                context: context,
                controller: controller,
              );
            },
            icon: const Icon(Icons.note_add_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NotebookContents(
        pages: pages,
        documents: documents,
        controller: controller,
        isImportingPdf: _isImportingPdf,
        onCreatePage: () {
          unawaited(
            _createPageWithSetup(context: context, controller: controller),
          );
        },
        onImportPdf: () {
          unawaited(_importPdf(controller));
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create page',
        onPressed: () async {
          await _createPageWithSetup(context: context, controller: controller);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _importPdf(page_app.PageController controller) async {
    if (_isImportingPdf) {
      return;
    }

    setState(() {
      _isImportingPdf = true;
    });

    try {
      final result = await controller.importPdf();

      if (!mounted || result == null) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${result.pages.length} pages from ${result.document.fileName}',
            ),
          ),
        );
    } catch (error, stackTrace) {
      debugPrint('PDF IMPORT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('This PDF could not be imported.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingPdf = false;
        });
      }
    }
  }

  Future<void> _createPageWithSetup({
    required BuildContext context,
    required page_app.PageController controller,
  }) async {
    final setup = await showPageSetupDialog(context: context);

    if (setup == null) {
      return;
    }

    await controller.createPage(
      orientation: setup.orientation,
      template: setup.template,
      paperColor: setup.paperColor,
    );
  }
}
