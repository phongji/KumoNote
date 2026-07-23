import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drawing/application/controllers/drawing_controller.dart';
import '../../../drawing/application/state/drawing_state.dart';
import '../../../drawing/presentation/widgets/scene_object_layer.dart';
import '../../../pdf/presentation/widgets/pdf_page_background.dart';
import '../../domain/entities/note_page.dart';
import '../painters/paper_template_painter.dart';

final class PageContentPreview extends ConsumerWidget {
  const PageContentPreview({required this.page, super.key});

  final NotePage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawing = ref.watch(drawingControllerProvider(page.id));

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: page.width,
            height: page.height,
            child: RepaintBoundary(
              child: ColoredBox(
                color: Color(page.paperColor.colorValue),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (page.pdfDocumentId case final documentId?)
                      PdfPageBackground(
                        documentId: documentId,
                        pageNumber: page.pdfPageNumber!,
                      )
                    else
                      CustomPaint(
                        painter: PaperTemplatePainter(
                          template: page.template,
                          lineColor: const Color(
                            0xFF7D8583,
                          ).withValues(alpha: 0.34),
                        ),
                      ),
                    drawing.maybeWhen(
                      data: (state) {
                        return SceneObjectLayer(
                          pageId: page.id,
                          strokes: state.strokes,
                          interactionMode: CanvasInteractionMode.navigation,
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
