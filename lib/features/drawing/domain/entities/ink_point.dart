final class InkPoint {
  const InkPoint({
    required this.x,
    required this.y,
    required this.pressure,
    required this.elapsedMicroseconds,
    this.tiltX = 0,
    this.tiltY = 0,
  }) : assert(pressure >= 0),
       assert(pressure <= 1);

  final double x;
  final double y;
  final double pressure;
  final int elapsedMicroseconds;
  final double tiltX;
  final double tiltY;

  InkPoint translate({required double deltaX, required double deltaY}) {
    return InkPoint(
      x: x + deltaX,
      y: y + deltaY,
      pressure: pressure,
      elapsedMicroseconds: elapsedMicroseconds,
      tiltX: tiltX,
      tiltY: tiltY,
    );
  }

  InkPoint scale({required double scaleX, required double scaleY}) {
    return InkPoint(
      x: x * scaleX,
      y: y * scaleY,
      pressure: pressure,
      elapsedMicroseconds: elapsedMicroseconds,
      tiltX: tiltX,
      tiltY: tiltY,
    );
  }

  double distanceSquaredTo(InkPoint other) {
    final deltaX = other.x - x;
    final deltaY = other.y - y;

    return (deltaX * deltaX) + (deltaY * deltaY);
  }
}
