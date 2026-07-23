import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../backup/application/providers/backup_providers.dart';
import '../../../export/application/providers/export_providers.dart';
import '../../../page/domain/entities/note_page.dart';
import '../../../pdf/application/pdf_providers.dart';
import '../../application/controllers/page_controller.dart' as page_app;
import '../../application/providers/page_providers.dart';
import '../widgets/notebook_contents.dart';
import '../widgets/page_setup_dialog.dart';
import 'page_trash_screen.dart';

enum _NotebookFileAction { importPdf, exportPdf, backup }

final class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({
    required this.notebookId,
    required this.notebookName,
    super.key,
  });

  final String notebookId;
  final String notebookName;

  @override
  ConsumerState<NotebookScreen> createState() {
    return _NotebookScreenState();
  }
}

final class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  bool _isImportingPdf = false;
  bool _isExportingPdf = false;
  bool _isBackingUp = false;
  String? _backupStage;
  int _exportedPageCount = 0;
  int _exportTotalPageCount = 0;

  bool get _isHandlingFile {
    return _isImportingPdf || _isExportingPdf || _isBackingUp;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final pages = ref.watch(activePageListProvider(widget.notebookId));
    final documents = ref.watch(pdfDocumentListProvider(widget.notebookId));
    final controller = ref.read(
      page_app.pageControllerProvider(widget.notebookId),
    );
    final pageItems = pages.asData?.value ?? const <NotePage>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebookName),
        actions: [
          if (_isHandlingFile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  if (_isExportingPdf && _exportTotalPageCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$_exportedPageCount/$_exportTotalPageCount',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ] else if (_isBackingUp) ...[
                    const SizedBox(width: 8),
                    Text(
                      _backupStageLabel(context),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
            )
          else
            PopupMenuButton<_NotebookFileAction>(
              tooltip: strings.moreActions,
              icon: const Icon(Icons.file_open_outlined),
              onSelected: (action) {
                switch (action) {
                  case _NotebookFileAction.importPdf:
                    unawaited(_importPdf(controller));
                    break;
                  case _NotebookFileAction.exportPdf:
                    unawaited(_exportPdf(pageItems));
                    break;
                  case _NotebookFileAction.backup:
                    unawaited(_createBackup());
                    break;
                }
              },
              itemBuilder: (context) {
                final isThai =
                    Localizations.localeOf(context).languageCode == 'th';

                return [
                  PopupMenuItem(
                    value: _NotebookFileAction.importPdf,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(strings.importPdf),
                    ),
                  ),
                  PopupMenuItem(
                    value: _NotebookFileAction.exportPdf,
                    enabled: pageItems.isNotEmpty,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.ios_share_outlined),
                      title: Text(isThai ? 'ส่งออกเป็น PDF' : 'Export as PDF'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _NotebookFileAction.backup,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(
                        isThai
                            ? 'สำรองสมุด (.kumo)'
                            : 'Back up notebook (.kumo)',
                      ),
                    ),
                  ),
                ];
              },
            ),
          IconButton(
            tooltip: strings.trash,
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
            tooltip: strings.createPage,
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
        tooltip: strings.createPage,
        onPressed: () async {
          await _createPageWithSetup(context: context, controller: controller);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _importPdf(page_app.PageController controller) async {
    if (_isHandlingFile) {
      return;
    }

    final strings = AppLocalizations.of(context)!;

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
              strings.pdfImported(
                result.pages.length,
                result.document.fileName,
              ),
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
        ..showSnackBar(SnackBar(content: Text(strings.pdfImportFailed)));
    } finally {
      if (mounted) {
        setState(() {
          _isImportingPdf = false;
        });
      }
    }
  }

  Future<void> _exportPdf(List<NotePage> pages) async {
    if (_isHandlingFile || pages.isEmpty) {
      return;
    }

    setState(() {
      _isExportingPdf = true;
      _exportedPageCount = 0;
      _exportTotalPageCount = pages.length;
    });

    try {
      await ref
          .read(notebookPdfExportServiceProvider)
          .export(
            notebookName: widget.notebookName,
            pages: pages,
            onProgress: (completed, total) {
              if (!mounted) {
                return;
              }

              setState(() {
                _exportedPageCount = completed;
                _exportTotalPageCount = total;
              });
            },
          );
    } catch (error, stackTrace) {
      debugPrint('PDF EXPORT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      final isThai = Localizations.localeOf(context).languageCode == 'th';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isThai
                  ? 'ยังส่งออกสมุดนี้ไม่ได้ กรุณาลองอีกครั้ง'
                  : 'This notebook could not be exported. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _exportedPageCount = 0;
          _exportTotalPageCount = 0;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    if (_isHandlingFile) {
      return;
    }

    setState(() {
      _isBackingUp = true;
      _backupStage = 'snapshot';
    });

    try {
      await ref
          .read(nativeBackupServiceProvider)
          .createNotebookBackup(
            notebookId: widget.notebookId,
            onStageChanged: (stage) {
              if (!mounted) {
                return;
              }

              setState(() {
                _backupStage = stage;
              });
            },
          );
    } catch (error, stackTrace) {
      debugPrint('NATIVE BACKUP ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      final isThai = Localizations.localeOf(context).languageCode == 'th';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isThai
                  ? 'ยังสำรองสมุดนี้ไม่ได้ กรุณาลองอีกครั้ง'
                  : 'This notebook could not be backed up. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _backupStage = null;
        });
      }
    }
  }

  String _backupStageLabel(BuildContext context) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';

    return switch (_backupStage) {
      'snapshot' => isThai ? 'รวบรวมข้อมูล…' : 'Collecting…',
      'assets' => isThai ? 'รวบรวมไฟล์…' : 'Collecting files…',
      'integrity' => isThai ? 'ตรวจความสมบูรณ์…' : 'Checking…',
      'archive' => isThai ? 'สร้างแพ็กเกจ…' : 'Packaging…',
      'share' => isThai ? 'เตรียมบันทึก…' : 'Preparing…',
      _ => isThai ? 'กำลังสำรอง…' : 'Backing up…',
    };
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
