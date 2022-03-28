import 'package:flutter/material.dart';

import '../anchor.dart';

abstract class EnhancedCompositedTransformAnchor {
  const EnhancedCompositedTransformAnchor();

  /// Returns the offset at which to position the follower element in relation
  /// to the top left of the [targetSize].
  ///
  /// The [followerSize] is the final size of the follower element after layout
  /// For example, if it is used in portals, it is based on the follower
  /// constraints determined by [Anchor.getFollowerConstraints].
  ///
  /// The [targetSize] represents the bounds of the element which the follower
  /// element should be anchored to. If it is used in portals, this must be
  /// the same value that is passed to [Anchor.getFollowerConstraints].
  ///
  /// The [theaterRect] represents the bounds of the full available space to
  /// place the follower element in. Note that this is also relative to the top
  /// left of the [targetSize].
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
  ///  * `Rect.fromLTWH(0, 0, 20, 20)` for the [targetSize].
  ///  * `Rect.fromLTWH(-40, -40, 100, 100)` for the [theaterRect].
  ///  * `Size(30, 30)` for the [followerSize].
  ///  * `Offset(20, 20)` as the return value.
  Offset getFollowerOffset({
    required Size followerSize,
    required Size targetSize,
    required Rect theaterRect,
  });
}

@immutable
class EnhancedCompositedTransformAligned
    implements EnhancedCompositedTransformAnchor {
  const EnhancedCompositedTransformAligned({
    required this.follower,
    required this.target,
    this.portal = Alignment.center,
    this.alignToPortal = const AxisFlag(),
    this.shiftToWithinBound = const AxisFlag(),
    this.offset = Offset.zero,
    this.backup,
    this.debugName,
  });

  final String? debugName;

  /// The reference point on the follower element.
  final Alignment follower;

  /// The reference point on the target element, if enabled
  final Alignment target;

  /// The reference point on the `Portal`, if enabled
  final Alignment portal;

  /// Whether to use [portal] instead of [target] for X and/or Y axis
  final AxisFlag alignToPortal;

  ///  for X and/or Y axis
  final AxisFlag shiftToWithinBound;

  /// Offset to shift the follower element by after all calculations are made.
  final Offset offset;

  /// If the calculated position would render the follower element out of bounds
  /// (for example, a tooltip would go off screen), a backup can be used.
  /// The offset calculations will fall back to the backup.
  final EnhancedCompositedTransformAnchor? backup;

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Size targetSize,
    required Rect theaterRect,
  }) {
    final followerAlignPortal = followerSize.alignedTo(
      theaterRect.size,
      followerAlignment: follower,
      targetAlignment: portal,
      offset: theaterRect.topLeft + offset,
    );
    final followerAlignTarget = followerSize.alignedTo(
      targetSize,
      followerAlignment: follower,
      targetAlignment: target,
      offset: offset,
    );

    final followerRectBeforeClamp = Rect.fromLTWH(
      alignToPortal.x ? followerAlignPortal.left : followerAlignTarget.left,
      alignToPortal.y ? followerAlignPortal.top : followerAlignTarget.top,
      alignToPortal.x ? followerAlignPortal.width : followerAlignTarget.width,
      alignToPortal.y ? followerAlignPortal.height : followerAlignTarget.height,
    );

    final followerRect = followerRectBeforeClamp.shiftToWithinBound(
        theaterRect, shiftToWithinBound);

    // print('hi getFollowerOffset '
    //     'followerSize=$followerSize targetSize=$targetSize theaterRect=$theaterRect '
    //     'followerAlignPortal=$followerAlignPortal followerAlignTarget=$followerAlignTarget '
    //     'followerRect=$followerRect');

    if (!theaterRect.fullyContains(followerRect)) {
      final backup = this.backup;
      if (backup != null) {
        return backup.getFollowerOffset(
          followerSize: followerSize,
          targetSize: targetSize,
          theaterRect: theaterRect,
        );
      }
    }

    return followerRect.topLeft;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! EnhancedCompositedTransformAligned) {
      return false;
    }
    return debugName == other.debugName &&
        follower == other.follower &&
        target == other.target &&
        offset == other.offset &&
        backup == other.backup;
  }

  @override
  int get hashCode => Object.hash(debugName, follower, target, offset, backup);

  @override
  String toString() => 'EnhancedCompositedTransformAligned{'
      'debugName: $debugName, '
      'follower: $follower, '
      'target: $target, '
      'offset: $offset, '
      'backup: $backup'
      '}';
}

@immutable
class AxisFlag {
  const AxisFlag({
    this.x = false,
    this.y = false,
  });

  final bool x;
  final bool y;
}

extension on Size {
  /// Returns a [Rect] that is aligned to the sizes (follower size / this and
  /// the target size) along the given alignments, shifted by [offset].
  Rect alignedTo(
    Size targetSize, {
    required Alignment followerAlignment,
    required Alignment targetAlignment,
    Offset offset = Offset.zero,
  }) {
    final followerOffset = targetAlignment.alongSize(targetSize) -
        followerAlignment.alongSize(this) +
        offset;
    return followerOffset & this;
  }
}

extension on Rect {
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

  Rect shiftToWithinBound(Rect bounds, AxisFlag enable) {
    return Rect.fromLTWH(
      enable.x ? left.softClamp(bounds.left, bounds.right - width) : left,
      enable.y ? top.softClamp(bounds.top, bounds.bottom - height) : top,
      width,
      height,
    );
  }
}

extension on double {
  double softClamp(double lowerLimit, double upperLimit) {
    if (lowerLimit > upperLimit) {
      return lowerLimit;
    }
    return clamp(lowerLimit, upperLimit).toDouble();
  }
}
