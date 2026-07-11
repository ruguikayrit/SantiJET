class CadTextEntity {
  const CadTextEntity({
    required this.entityType,
    required this.text,
    this.x,
    this.y,
    this.layer,
  });

  final String entityType;
  final String text;
  final double? x;
  final double? y;
  final String? layer;

  bool get hasPosition => x != null && y != null;

  /// CAD koordinatında üstten alta, soldan sağa okuma sırası.
  int compareDrawingOrder(CadTextEntity other) {
    final yA = y ?? double.negativeInfinity;
    final yB = other.y ?? double.negativeInfinity;
    final yCompare = yB.compareTo(yA);
    if (yCompare != 0) return yCompare;

    final xA = x ?? double.infinity;
    final xB = other.x ?? double.infinity;
    return xA.compareTo(xB);
  }

  CadTextEntity copyWith({
    String? entityType,
    String? text,
    double? x,
    double? y,
    String? layer,
  }) {
    return CadTextEntity(
      entityType: entityType ?? this.entityType,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      layer: layer ?? this.layer,
    );
  }
}
