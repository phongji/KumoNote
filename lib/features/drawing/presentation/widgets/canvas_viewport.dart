import 'package:flutter/material.dart';

final class CanvasViewport extends StatefulWidget {
  const CanvasViewport({
    required this.navigationEnabled,
    required this.child,
    super.key,
  });

  final bool navigationEnabled;
  final Widget child;

  @override
  State<CanvasViewport> createState() {
    return _CanvasViewportState();
  }
}

final class _CanvasViewportState extends State<CanvasViewport> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      panEnabled: widget.navigationEnabled,
      scaleEnabled: widget.navigationEnabled,
      trackpadScrollCausesScale: true,
      minScale: 0.35,
      maxScale: 4,
      boundaryMargin: const EdgeInsets.all(600),
      clipBehavior: Clip.hardEdge,
      constrained: false,
      interactionEndFrictionCoefficient: 0.0000135,
      child: widget.child,
    );
  }
}
