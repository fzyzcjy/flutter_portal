// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, curly_braces_in_flow_control_structures, omit_local_variable_types, comment_references, always_put_control_body_on_new_line

import 'package:flutter/rendering.dart';

import '../anchor.dart';
import '../portal_link.dart';
import 'rendering_layer.dart';

/// @nodoc
class CustomRenderLeaderLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderLeaderLayer({
    required CustomLayerLink link,
    RenderBox? child,
  })  : assert(link != null),
        _link = link,
        super(child);

  /// @nodoc
  CustomLayerLink get link => _link;
  CustomLayerLink _link;
  set link(CustomLayerLink value) {
    assert(value != null);
    if (_link == value) return;
    _link.leaderSize = null;
    _link = value;
    if (_previousLayoutSize != null) {
      _link.leaderSize = _previousLayoutSize;
    }
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  // The latest size of this [RenderBox], computed during the previous layout
  // pass. It should always be equal to [size], but can be accessed even when
  // [debugDoingThisResize] and [debugDoingThisLayout] are false.
  Size? _previousLayoutSize;

  @override
  void performLayout() {
    super.performLayout();
    _previousLayoutSize = size;
    link.leaderSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = CustomLeaderLayer(link: link, offset: offset);
    } else {
      final CustomLeaderLayer leaderLayer = layer! as CustomLeaderLayer;
      leaderLayer
        ..link = link
        ..offset = offset;
    }
    context.pushLayer(layer!, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
  }
}

/// @nodoc
class CustomRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderFollowerLayer({
    required CustomLayerLink link,
    // NOTE MODIFIED some arguments
    required OverlayLink overlayLink,
    required Size targetSize,
    required Anchor anchor,
    RenderBox? child,
  })  : _anchor = anchor,
        _link = link,
        _overlayLink = overlayLink,
        _targetSize = targetSize,
        super(child);

  // NOTE MODIFIED original Flutter code lets user pass it in as an argument,
  // but we just make it a constant zero.
  static const showWhenUnlinked = false;

  /// @nodoc
  Anchor get anchor => _anchor;
  Anchor _anchor;

  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  /// @nodoc
  CustomLayerLink get link => _link;
  CustomLayerLink _link;

  set link(CustomLayerLink value) {
    if (_link == value) {
      return;
    }
    _link = value;
    markNeedsPaint();
  }

  /// @nodoc
  OverlayLink get overlayLink => _overlayLink;
  OverlayLink _overlayLink;

  set overlayLink(OverlayLink value) {
    if (_overlayLink == value) {
      return;
    }
    _overlayLink = value;
    markNeedsPaint();
  }

  /// @nodoc
  Size get targetSize => _targetSize;
  Size _targetSize;

  set targetSize(Size value) {
    if (_targetSize == value) {
      return;
    }
    _targetSize = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  /// @nodoc
  @override
  CustomFollowerLayer? get layer => super.layer as CustomFollowerLayer?;

  /// @nodoc
  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Disables the hit testing if this render object is hidden.
    if (link.leader == null && !showWhenUnlinked) return false;
    // RenderFollowerLayer objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: getCurrentTransform(),
      position: position,
      hitTest: (result, position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  // NOTE MODIFIED added
  /// Returns the linked offset in relation to the leader layer.
  ///
  /// The [LeaderLayer] is inserted by the [CompositedTransformTarget] in
  /// [PortalTarget].
  ///
  /// The reason we cannot simply access the [link]'s leader in [paint] is that
  /// the leader is only attached to the [CustomLayerLink] in [LeaderLayer.attach],
  /// which is called in the compositing phase which is after the paint phase.
  Offset _computeLinkedOffset(Offset leaderOffset) {
    assert(
      overlayLink.theater != null,
      'The theater must be set in the OverlayLink when the '
      '_RenderPortalTheater is inserted as a child of the _PortalLinkScope. '
      'Therefore, it must not be null in any child PortalEntry.',
    );
    final theater = overlayLink.theater!;

    // In order to compute the theater rect, we must first offset (shift) it by
    // the position of the top-left corner of the target in the coordinate space
    // of the theater since we are working with it relative to the target.
    final theaterShift = -globalToLocal(
      leaderOffset,
      ancestor: theater,
    );

    final theaterRect = theaterShift & theater.size;

    return anchor.getFollowerOffset(
      // The size is set in performLayout of the RenderProxyBoxMixin.
      followerSize: size,
      targetSize: targetSize,
      portalRect: theaterRect,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // NOTE MODIFIED removed original [effectiveLinkedOffset] calculation, and replace with callback

    if (layer == null) {
      layer = CustomFollowerLayer(
        link: link,
        linkedOffsetCallback: _computeLinkedOffset,
      );
    } else {
      layer
        ?..link = link
        ..linkedOffsetCallback = _computeLinkedOffset;
    }

    context.pushLayer(
      layer!,
      super.paint,
      Offset.zero,
      childPaintBounds: const Rect.fromLTRB(
        // We don't know where we'll end up, so we have no idea what our cull rect should be.
        double.negativeInfinity,
        double.negativeInfinity,
        double.infinity,
        double.infinity,
      ),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(getCurrentTransform());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
    properties
        .add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
