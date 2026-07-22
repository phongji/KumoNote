import 'package:flutter/material.dart';
import 'package:kumo_note/l10n/app_localizations.dart';

import '../../domain/entities/note_page.dart';
import '../painters/paper_template_painter.dart';

final class PageSetup {
  const PageSetup({
    required this.orientation,
    required this.template,
    required this.paperColor,
  });

  final PageOrientation orientation;
  final PageTemplate template;
  final PagePaperColor paperColor;
}

Future<PageSetup?> showPageSetupDialog({required BuildContext context}) {
  return showDialog<PageSetup>(
    context: context,
    builder: (context) {
      return const _PageSetupDialog();
    },
  );
}

final class _PageSetupDialog extends StatefulWidget {
  const _PageSetupDialog();

  @override
  State<_PageSetupDialog> createState() {
    return _PageSetupDialogState();
  }
}

final class _PageSetupDialogState extends State<_PageSetupDialog> {
  PageOrientation _orientation = PageOrientation.portrait;
  PageTemplate _template = PageTemplate.blank;
  PagePaperColor _paperColor = PagePaperColor.paperWhite;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.chooseYourPaper),
          const SizedBox(height: 4),
          Text(
            strings.paperSetupHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        height: 580,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pageDirection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            SegmentedButton<PageOrientation>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: PageOrientation.portrait,
                  icon: const Icon(Icons.stay_current_portrait_outlined),
                  label: Text(strings.portrait),
                ),
                ButtonSegment(
                  value: PageOrientation.landscape,
                  icon: const Icon(Icons.stay_current_landscape_outlined),
                  label: Text(strings.landscape),
                ),
              ],
              selected: {_orientation},
              onSelectionChanged: (selection) {
                setState(() {
                  _orientation = selection.first;
                });
              },
            ),
            const SizedBox(height: 22),
            Text(
              strings.paperStyle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnCount = constraints.maxWidth >= 520 ? 4 : 2;

                  return GridView.builder(
                    itemCount: PageTemplate.values.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.76,
                    ),
                    itemBuilder: (context, index) {
                      final template = PageTemplate.values[index];

                      return _TemplateTile(
                        template: template,
                        title: _templateTitle(strings, template),
                        paperColor: _paperColor,
                        isSelected: template == _template,
                        onTap: () {
                          setState(() {
                            _template = template;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              strings.paperTone,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final paperColor in PagePaperColor.values)
                    _PaperColorButton(
                      paperColor: paperColor,
                      isSelected: paperColor == _paperColor,
                      onTap: () {
                        setState(() {
                          _paperColor = paperColor;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(strings.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(
              PageSetup(
                orientation: _orientation,
                template: _template,
                paperColor: _paperColor,
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: Text(strings.createPage),
        ),
      ],
    );
  }

  String _templateTitle(AppLocalizations strings, PageTemplate template) {
    return switch (template) {
      PageTemplate.blank => strings.clearTemplate,
      PageTemplate.ruled => strings.calmLines,
      PageTemplate.grid => strings.softGrid,
      PageTemplate.dotted => strings.gentleDots,
      PageTemplate.guideRuled => strings.guidedLines,
      PageTemplate.focusHeader => strings.quietFocus,
      PageTemplate.twinNotes => strings.twinSpace,
      PageTemplate.quietChecklist => strings.quietChecklist,
    };
  }
}

final class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.title,
    required this.paperColor,
    required this.isSelected,
    required this.onTap,
  });

  final PageTemplate template;
  final String title;
  final PagePaperColor paperColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(paperColor.colorValue),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: PaperTemplatePainter(
                          template: template,
                          lineColor: const Color(
                            0xFF7D8583,
                          ).withValues(alpha: 0.34),
                        ),
                      ),
                      if (isSelected)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              Icons.check_circle,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PaperColorButton extends StatelessWidget {
  const _PaperColorButton({
    required this.paperColor,
    required this.isSelected,
    required this.onTap,
  });

  final PagePaperColor paperColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(paperColor.colorValue),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 18, color: colorScheme.primary)
            : null,
      ),
    );
  }
}
