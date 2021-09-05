import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// The logic of layout and positioning of a source element in relation to a
/// target element.
///
/// Independent of the underlying rendering implementation.
abstract class Anchor {
  /// Return the layout constraints that are given to the source element given:
  /// - [targetRect] the bounds of the element which the source element should
  /// be anchored to. No assumptions should be made about the coordinate space.
  /// - [overlayConstraints] the available space to render the source element
  BoxConstraints getSourceConstraints({
    required Rect targetRect,
    required BoxConstraints overlayConstraints,
  });

  /// Return the offset at which to position the source element in relation to
  /// to the top-left corner of [targetRect] given:
  /// - [sourceSize] the final calculated size of the source element
  /// - [targetRect] the bounds of the element which the source should be
  /// anchored to. Should be the same value passed in from [getSourceConstraints]
  /// - [overlayRect] the bounds of the full available space to render the
  /// source element
  Offset getSourceOffset({
    required Size sourceSize,
    required Rect targetRect,
    required Rect overlayRect,
  });
}

/// The source element should ignore any information about the target and expand
/// to fill the bounds of the overlay
@immutable
class Filled implements Anchor {
  const Filled();

  @override
  BoxConstraints getSourceConstraints({
    required Rect targetRect,
    required BoxConstraints overlayConstraints,
  }) {
    return BoxConstraints.tight(overlayConstraints.biggest);
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

/// Align a point of the source element with a point on the target element
/// Can optionally pass a [widthFactor] or [heightFactor] so the source element
/// gets a size as a factor of the target element.
/// Can optionally pass a [backup] which will be used if the element is going
/// to be rendered off screen.
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

  /// The reference point on the source element
  final Alignment source;

  /// The reference point on the target element
  final Alignment target;

  /// Offset to shift the source element by after all calculations are made
  final Offset offset;

  /// The width to make the source element as a multiple of the width of the
  /// target element. An autocomplete widget may set this to 1 so the popup
  /// width matches the the text field width
  final double? widthFactor;

  /// The height to make the source element as a multiple of the height of the
  /// target element.
  final double? heightFactor;

  /// If the calculated position would render the source element out of bounds
  /// (for example, a tooltip would go off screen), a backup can be used.
  /// The offset calculations will fall back to the backup.
  final Anchor? backup;

  @override
  BoxConstraints getSourceConstraints({
    required Rect targetRect,
    required BoxConstraints overlayConstraints,
  }) {
    final widthFactor = this.widthFactor;
    final heightFactor = this.heightFactor;

    return overlayConstraints.loosen().tighten(
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

extension _RectAnchorExt on Rect {
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
