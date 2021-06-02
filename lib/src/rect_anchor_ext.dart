import 'dart:ui' show Rect, Offset;

import 'package:flutter/widgets.dart' show Alignment;

extension RectAnchorExt on Rect {
  Rect alignedTo(
    Rect target, {
    required Alignment sourceAlignment,
    required Alignment targetAlignment,
    Offset offset = Offset.zero,
  }) {
    final sourceOffset = targetAlignment.alongSize(target.size) -
        sourceAlignment.alongSize(size) +
        target.topLeft +
        offset;
    return sourceOffset & size;
  }

  /// Returns true if [rect] is fully contained within this rect
  /// If the [rect] has any part that lies outside of this parent
  /// false will be returned
  bool fullyContains(Rect rect) =>
      contains(rect.topLeft) && contains(rect.bottomRight);
}
