import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'enhanced_composited_transform/anchor.dart';

export 'enhanced_composited_transform/anchor.dart' show AxisFlag;

/// The logic of layout and positioning of a follower element in relation to a
/// target element.
///
/// This is independent of the underlying rendering implementation.
abstract class Anchor extends EnhancedCompositedTransformAnchor {
  const Anchor();

  /// Returns the layout constraints that are given to the follower element.
  ///
  /// The [targetSize] represents the bounds of the element which the follower
  /// element should be anchored to. This must be the same value that is passed
  /// to [getFollowerOffset]. No assumptions should be made about the coordinate
  /// space, i.e. only the size of the target should be considered.
  ///
  /// The [theaterConstraints] represent the full available space to place the
  /// follower element in. This is irrespective of where the target is
  /// positioned within the full available space.
  BoxConstraints getFollowerConstraints({
    required Size targetSize,
    required BoxConstraints theaterConstraints,
  });
}

/// The follower element should ignore any information about the target and
/// expand to fill the bounds of the overlay
@immutable
class Filled implements Anchor {
  const Filled();

  @override
  BoxConstraints getFollowerConstraints({
    required Size targetSize,
    required BoxConstraints theaterConstraints,
  }) {
    return BoxConstraints.tight(theaterConstraints.biggest);
  }

  @override
  Offset getFollowerOffset({
    required Size followerSize,
    required Size targetSize,
    required Rect theaterRect,
  }) {
    return Offset.zero;
  }
}

/// Align a point of the follower element with a point on the target element
/// Can optionally pass a [widthFactor] or [heightFactor] so the follower
/// element gets a size as a factor of the target element.
/// Can optionally pass a [backup] which will be used if the element is going
/// to be rendered off screen.
@immutable
class Aligned extends EnhancedCompositedTransformAligned
    implements Anchor, EnhancedCompositedTransformAnchor {
  const Aligned({
    required Alignment follower,
    required Alignment target,
    Alignment portal = Alignment.center,
    AxisFlag alignToPortal = const AxisFlag(),
    AxisFlag shiftToWithinBound = const AxisFlag(),
    Offset offset = Offset.zero,
    EnhancedCompositedTransformAnchor? backup,
    String? debugName,
    this.widthFactor,
    this.heightFactor,
  }) : super(
          follower: follower,
          target: target,
          portal: portal,
          alignToPortal: alignToPortal,
          shiftToWithinBound: shiftToWithinBound,
          offset: offset,
          backup: backup,
          debugName: debugName,
        );

  static const center = Aligned(
    follower: Alignment.center,
    target: Alignment.center,
  );

  /// The width to make the follower element as a multiple of the width of the
  /// target element.
  ///
  /// An autocomplete widget may set this to 1 so the popup width matches the
  /// text field width.
  final double? widthFactor;

  /// The height to make the follower element as a multiple of the height of the
  /// target element.
  final double? heightFactor;

  @override
  BoxConstraints getFollowerConstraints({
    required Size targetSize,
    required BoxConstraints theaterConstraints,
  }) {
    final widthFactor = this.widthFactor;
    final heightFactor = this.heightFactor;

    return theaterConstraints.loosen().tighten(
          width: widthFactor == null ? null : targetSize.width * widthFactor,
          height:
              heightFactor == null ? null : targetSize.height * heightFactor,
        );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Aligned) {
      return false;
    }
    return super == other &&
        widthFactor == other.widthFactor &&
        heightFactor == other.heightFactor;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, widthFactor, heightFactor);
}
