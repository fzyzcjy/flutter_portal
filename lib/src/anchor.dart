import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// The logic of layout and positioning of a follower element in relation to a
/// target element.
///
/// This is independent of the underlying rendering implementation.
abstract class Anchor {
  /// Returns the layout constraints that are given to the follower element.
  ///
  /// The [targetRect] represents the bounds of the element which the follower
  /// element should be anchored to. This must be the same value that is passed
  /// to [getFollowerOffset]. No assumptions should be made about the coordinate
  /// space, i.e. only the size of the target should be considered.
  ///
  /// The [portalConstraints] represent the full available space to place the
  /// source element in. This is irrespective of where the target is positioned
  /// within the full available space.
  BoxConstraints getFollowerConstraints({
    required Rect targetRect,
    required BoxConstraints portalConstraints,
  });

  /// Returns the offset at which to position the follower element in relation
  /// to the top left of the [targetRect].
  ///
  /// The [followerSize] is the final size of the follower element after layout
  /// based on the source constraints determined by [getFollowerConstraints].
  ///
  /// The [targetRect] represents the bounds of the element which the follower
  /// element should be anchored to. This must be the same value that is passed
  /// to [getFollowerConstraints].
  ///
  /// The [portalRect] represents the bounds of the full available space to
  /// place the follower element in. Note that this is also relative to the top
  /// left of the [targetRect].
  /// This means that every offset going into or coming out of this function is
  /// relative to the top-left corner of the target.
  ///
  /// ## Example
  ///
  /// In this example, our follower element has a size of `Size(30, 30)` and
  /// should be anchored to the bottom right of the target.
  ///
  /// If we assume the full available space starts at absolute `(0, 0)` and
  /// spans to absolute `(100, 100)` and the target rect starts at absolute
  /// `(40, 40)` and spans to absolute `(60, 60)`, the passed values will be:
  ///
  ///  * `Rect.fromLTWH(0, 0, 20, 20)` for the [targetRect].
  ///  * `Rect.fromLTWH(-40, -40, 100, 100)` for the [portalRect].
  ///  * `Size(30, 30)` for the [followerSize].
  ///  * `Offset(20, 20)` as the return value.
  Offset getFollowerOffset({
    required Size followerSize,
    required Rect targetRect,
    required Rect portalRect,
  });
}

/// The source element should ignore any information about the target and expand
/// to fill the bounds of the overlay
@immutable
class Filled implements Anchor {
  const Filled();

  @override
  BoxConstraints getFollowerConstraints({
    required Rect targetRect,
    required BoxConstraints portalConstraints,
  }) {
    return BoxConstraints.tight(portalConstraints.biggest);
  }

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Rect targetRect,
    required Rect portalRect,
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
  BoxConstraints getFollowerConstraints({
    required Rect targetRect,
    required BoxConstraints portalConstraints,
  }) {
    final widthFactor = this.widthFactor;
    final heightFactor = this.heightFactor;

    return portalConstraints.loosen().tighten(
          width: widthFactor == null ? null : targetRect.width * widthFactor,
          height:
              heightFactor == null ? null : targetRect.height * heightFactor,
        );
  }

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Rect targetRect,
    required Rect portalRect,
  }) {
    final sourceRect = (Offset.zero & followerSize).alignedTo(
      targetRect,
      sourceAlignment: source,
      targetAlignment: target,
      offset: offset,
    );

    if (!portalRect.fullyContains(sourceRect)) {
      final backup = this.backup;
      if (backup != null) {
        return backup.getFollowerOffset(
          followerSize: followerSize,
          targetRect: targetRect,
          portalRect: portalRect,
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

extension on Rect {
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
      containsIncludingBottomAndRightEdge(rect.topLeft) &&
      containsIncludingBottomAndRightEdge(rect.bottomRight);

  /// Whether the point specified by the given offset (which is assumed to be
  /// relative to the origin) lies between the left and right and the top and
  /// bottom edges of this rectangle.
  ///
  /// This is like [contains] but also includes the bottom edge and the right
  /// edge because in the context of painting, it would make no sense to
  /// consider a rect as overflowing when it lines up exactly with another rect.
  bool containsIncludingBottomAndRightEdge(Offset offset) {
    return offset.dx >= left &&
        offset.dx <= right &&
        offset.dy >= top &&
        offset.dy <= bottom;
  }
}
