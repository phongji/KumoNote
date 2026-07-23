import 'package:flutter/material.dart';

import '../../application/models/native_backup_preview.dart';

Future<String?> showNativeBackupPreviewDialog({
  required BuildContext context,
  required NativeBackupPreview preview,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _NativeBackupPreviewDialog(preview: preview);
    },
  );
}

final class _NativeBackupPreviewDialog extends StatefulWidget {
  const _NativeBackupPreviewDialog({required this.preview});

  final NativeBackupPreview preview;

  @override
  State<_NativeBackupPreviewDialog> createState() {
    return _NativeBackupPreviewDialogState();
  }
}

final class _NativeBackupPreviewDialogState
    extends State<_NativeBackupPreviewDialog> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: '${widget.preview.manifest.notebookTitle} (Restored)',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    final colorScheme = Theme.of(context).colorScheme;
    final preview = widget.preview;

    return AlertDialog(
      icon: const Icon(Icons.inventory_2_outlined),
      title: Text(isThai ? 'ตรวจสอบไฟล์สำรอง' : 'Review backup'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _PreviewRow(
                        label: isThai ? 'สมุดต้นฉบับ' : 'Original notebook',
                        value: preview.manifest.notebookTitle,
                      ),
                      _PreviewRow(
                        label: isThai ? 'จำนวนหน้า' : 'Pages',
                        value: '${preview.pageCount}',
                      ),
                      _PreviewRow(
                        label: isThai ? 'เส้นเขียน' : 'Strokes',
                        value: '${preview.strokeCount}',
                      ),
                      _PreviewRow(
                        label: isThai ? 'ข้อความ' : 'Text objects',
                        value: '${preview.textObjectCount}',
                      ),
                      _PreviewRow(
                        label: isThai ? 'รูปภาพ' : 'Images',
                        value: '${preview.imageObjectCount}',
                      ),
                      _PreviewRow(
                        label: isThai ? 'เอกสาร PDF' : 'PDF documents',
                        value: '${preview.pdfDocumentCount}',
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                autofocus: true,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: isThai ? 'ชื่อสมุดสำเนา' : 'Copy name',
                  helperText: isThai
                      ? 'สมุดเดิมจะไม่ถูกแก้ไข'
                      : 'The existing notebook will not be changed.',
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isThai ? 'ยกเลิก' : 'Cancel'),
        ),
        FilledButton.icon(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(_titleController.text.trim());
                },
          icon: const Icon(Icons.restore_rounded),
          label: Text(isThai ? 'คืนเป็นสำเนา' : 'Restore as copy'),
        ),
      ],
    );
  }
}

final class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              const SizedBox(width: 16),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
