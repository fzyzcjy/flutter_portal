// ignore_for_file: unnecessary_null_comparison, curly_braces_in_flow_control_structures, omit_local_variable_types, comment_references, always_put_control_body_on_new_line

import 'package:flutter/rendering.dart';

import 'layer.dart';

/// Provides an anchor for a [RenderFollowerLayer].
///
/// See also:
///
///  * [CompositedTransformTarget], the corresponding widget.
///  * [MyLeaderLayer], the layer that this render object creates.
class MyRenderLeaderLayer extends RenderProxyBox {
  /// Creates a render object that uses a [MyLeaderLayer].
  ///
  /// The [link] must not be null.
  MyRenderLeaderLayer({
    required MyLayerLink link,
    RenderBox? child,
  })  : assert(link != null),
        _link = link,
        super(child);

  /// The link object that connects this [MyRenderLeaderLayer] with one or more
  /// [RenderFollowerLayer]s.
  ///
  /// This property must not be null. The object must not be associated with
  /// another [MyRenderLeaderLayer] that is also being painted.
  MyLayerLink get link => _link;
  MyLayerLink _link;
  set link(MyLayerLink value) {
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
      layer = MyLeaderLayer(link: link, offset: offset);
    } else {
      final MyLeaderLayer leaderLayer = layer! as MyLeaderLayer;
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
    properties.add(DiagnosticsProperty<MyLayerLink>('link', link));
  }
}
