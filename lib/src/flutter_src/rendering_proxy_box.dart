// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, curly_braces_in_flow_control_structures, omit_local_variable_types, comment_references, always_put_control_body_on_new_line

import 'package:flutter/rendering.dart';

import '../anchor.dart';
import 'rendering_layer.dart';

/// @nodoc
class CustomRenderLeaderLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderLeaderLayer({
    required CustomLayerLink link,
    // NOTE MODIFIED some arguments
    required CustomCompositedTransformTheaterInfo theaterInfo,
    required String? debugName,
    RenderBox? child,
  })  : assert(link != null),
        _link = link,
        _theaterInfo = theaterInfo,
        _debugName = debugName,
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

  /// @nodoc
  CustomCompositedTransformTheaterInfo get theaterInfo => _theaterInfo;
  CustomCompositedTransformTheaterInfo _theaterInfo;

  set theaterInfo(CustomCompositedTransformTheaterInfo value) {
    if (_theaterInfo == value) {
      return;
    }
    _theaterInfo = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  // The latest size of this [RenderBox], computed during the previous layout
  // pass. It should always be equal to [size], but can be accessed even when
  // [debugDoingThisResize] and [debugDoingThisLayout] are false.
  Size? _previousLayoutSize;

  // NOTE MODIFIED add
  String? get debugName => _debugName;
  String? _debugName;
  set debugName(String? value) {
    if (_debugName == value) return;
    _debugName = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    _previousLayoutSize = size;
    link.leaderSize = size;
  }

  Rect _theaterRectRelativeToLeader() {
    return theaterInfo.theaterRectRelativeToLeader(this);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = CustomLeaderLayer(
        link: link,
        offset: offset,
        theaterRectRelativeToLeader: _theaterRectRelativeToLeader,
        debugName: debugName,
      );
    } else {
      final CustomLeaderLayer leaderLayer = layer! as CustomLeaderLayer;
      leaderLayer
        ..link = link
        ..offset = offset
        ..theaterRectRelativeToLeader = _theaterRectRelativeToLeader
        ..debugName = debugName;
    }
    context.pushLayer(layer!, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
    properties.add(DiagnosticsProperty<CustomCompositedTransformTheaterInfo>(
        'theaterInfo', theaterInfo));
    properties.add(DiagnosticsProperty('debugName', debugName));
  }
}

/// @nodoc
class CustomRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderFollowerLayer({
    required CustomLayerLink link,
    // NOTE MODIFIED some arguments
    required CustomCompositedTransformTheaterInfo theaterInfo,
    required Size targetSize,
    required Anchor anchor,
    required String? debugName,
    RenderBox? child,
  })  : _anchor = anchor,
        _link = link,
        _theaterInfo = theaterInfo,
        _targetSize = targetSize,
        _debugName = debugName,
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
  CustomCompositedTransformTheaterInfo get theaterInfo => _theaterInfo;
  CustomCompositedTransformTheaterInfo _theaterInfo;

  set theaterInfo(CustomCompositedTransformTheaterInfo value) {
    if (_theaterInfo == value) {
      return;
    }
    _theaterInfo = value;
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

  // NOTE MODIFIED add
  String? get debugName => _debugName;
  String? _debugName;
  set debugName(String? value) {
    if (_debugName == value) return;
    _debugName = value;
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
  Offset _computeLinkedOffset() {
    return anchor.getFollowerOffset(
      // The size is set in performLayout of the RenderProxyBoxMixin.
      followerSize: size,
      targetSize: targetSize,
      theaterRect: link.leader!.theaterRectRelativeToLeader(),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // NOTE MODIFIED removed original [effectiveLinkedOffset] calculation, and replace with callback

    if (layer == null) {
      layer = CustomFollowerLayer(
        link: link,
        linkedOffsetCallback: _computeLinkedOffset,
        unlinkedOffset: offset,
        debugName: debugName,
      );
    } else {
      layer
        ?..link = link
        ..linkedOffsetCallback = _computeLinkedOffset
        ..unlinkedOffset = offset
        ..debugName = debugName;
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
    properties.add(DiagnosticsProperty<CustomCompositedTransformTheaterInfo>(
        'theaterInfo', theaterInfo));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
    properties.add(DiagnosticsProperty('debugName', debugName));
  }
}

// ignore: one_member_abstracts
abstract class CustomCompositedTransformTheaterInfo {
  Rect theaterRectRelativeToLeader(CustomRenderLeaderLayer leaderLayer);
}
