import 'package:flutter/widgets.dart';

import 'rect_anchor_ext.dart';

abstract class Anchor {
  /// The constraints that are given to the source popup based on the rect of
  /// the target element
  BoxConstraints getSourceConstraints(
    BoxConstraints constraints,
    Rect targetRect,
  );

  Offset getSourceOffset({
    required Size sourceSize,
    required Rect targetRect,
    required Rect overlayRect,
  });
}

@immutable
class FullScreen implements Anchor {
  const FullScreen();

  @override
  BoxConstraints getSourceConstraints(
    BoxConstraints constraints,
    Rect targetRect,
  ) {
    return BoxConstraints.tight(constraints.biggest);
  }

  @override
  Offset getSourceOffset({
    required Size sourceSize,
    required Rect targetRect,
    required Rect overlayRect,
  }) {
    return Offset.zero;
  }
}

@immutable
class Aligned implements Anchor {
  const Aligned({
    required this.source,
    required this.target,
    this.offset = Offset.zero,
    this.widthFactor,
    this.heightFactor,
    this.backup,
  });

  static const center = Aligned(
    source: Alignment.center,
    target: Alignment.center,
  );

  final Alignment source;
  final Alignment target;
  final Offset offset;

  final double? widthFactor;
  final double? heightFactor;

  final Anchor? backup;

  @override
  BoxConstraints getSourceConstraints(
    BoxConstraints constraints,
    Rect targetRect,
  ) {
    final widthFactor = this.widthFactor;
    final heightFactor = this.heightFactor;

    return constraints.loosen().tighten(
          width: widthFactor == null ? null : targetRect.width * widthFactor,
          height:
              heightFactor == null ? null : targetRect.height * heightFactor,
        );
  }

  @override
  Offset getSourceOffset({
    required Size sourceSize,
    required Rect targetRect,
    required Rect overlayRect,
  }) {
    final sourceRect = (Offset.zero & sourceSize).alignedTo(
      targetRect,
      sourceAlignment: source,
      targetAlignment: target,
      offset: offset,
    );

    if (!overlayRect.fullyContains(sourceRect)) {
      final backup = this.backup;
      if (backup != null) {
        return backup.getSourceOffset(
          sourceSize: sourceSize,
          targetRect: targetRect,
          overlayRect: overlayRect,
        );
      }
    }

    return sourceRect.topLeft;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Aligned) {
      return false;
    }
    return source == other.source &&
        target == other.target &&
        offset == other.offset &&
        backup == other.backup;
  }

  @override
  int get hashCode => source.hashCode ^ target.hashCode ^ offset.hashCode;
}
