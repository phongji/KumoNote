import '../../domain/entities/ink_point.dart';

final class InkPointRecord {
  const InkPointRecord({
    required this.x,
    required this.y,
    required this.pressure,
    required this.elapsedMicroseconds,
    required this.tiltX,
    required this.tiltY,
  });

  final double x;
  final double y;
  final double pressure;
  final int elapsedMicroseconds;
  final double tiltX;
  final double tiltY;

  factory InkPointRecord.fromDomain(InkPoint point) {
    return InkPointRecord(
      x: point.x,
      y: point.y,
      pressure: point.pressure,
      elapsedMicroseconds: point.elapsedMicroseconds,
      tiltX: point.tiltX,
      tiltY: point.tiltY,
    );
  }

  factory InkPointRecord.fromJson(Map<String, Object?> json) {
    return InkPointRecord(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
      elapsedMicroseconds: (json['elapsedMicroseconds'] as num).toInt(),
      tiltX: (json['tiltX'] as num?)?.toDouble() ?? 0,
      tiltY: (json['tiltY'] as num?)?.toDouble() ?? 0,
    );
  }

  InkPoint toDomain() {
    return InkPoint(
      x: x,
      y: y,
      pressure: pressure,
      elapsedMicroseconds: elapsedMicroseconds,
      tiltX: tiltX,
      tiltY: tiltY,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
      'elapsedMicroseconds': elapsedMicroseconds,
      'tiltX': tiltX,
      'tiltY': tiltY,
    };
  }
}
