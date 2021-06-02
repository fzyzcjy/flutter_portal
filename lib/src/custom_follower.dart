import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'anchor.dart';
import 'portal.dart';

/// @nodoc
class MyCompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// @nodoc
  const MyCompositedTransformFollower({
    Key? key,
    required this.link,
    required this.overlayLink,
    required this.targetSize,
    required this.anchor,
    Widget? child,
  }) : super(key: key, child: child);

  /// @nodoc
  final Anchor anchor;

  /// @nodoc
  final LayerLink link;

  /// @nodoc
  final OverlayLink overlayLink;

  /// @nodoc
  final Size targetSize;

  @override
  MyRenderFollowerLayer createRenderObject(BuildContext context) {
    return MyRenderFollowerLayer(
      anchor: anchor,
      link: link,
      overlayLink: overlayLink,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    MyRenderFollowerLayer renderObject,
  ) {
    renderObject
      ..link = link
      ..overlayLink = overlayLink
      ..targetSize = targetSize
      ..anchor = anchor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Anchor>('anchor', anchor));
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(DiagnosticsProperty<Size>('targetSize', targetSize));
  }
}

/// @nodoc
class MyRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  MyRenderFollowerLayer({
    required LayerLink link,
    required OverlayLink overlayLink,
    required Size targetSize,
    required Anchor anchor,
    RenderBox? child,
  })  : _anchor = anchor,
        _link = link,
        _overlayLink = overlayLink,
        _targetSize = targetSize,
        super(child);

  Anchor _anchor;

  /// @nodoc
  Anchor get anchor => _anchor;
  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  LayerLink _link;

  /// @nodoc
  LayerLink get link => _link;
  set link(LayerLink value) {
    if (_link == value) {
      return;
    }
    _link = value;
    markNeedsPaint();
  }

  OverlayLink _overlayLink;
  OverlayLink get overlayLink => _overlayLink;
  set overlayLink(OverlayLink value) {
    if (_overlayLink == value) {
      return;
    }
    _overlayLink = value;
    markNeedsPaint();
  }

  Size _targetSize;

  /// @nodoc
  Size get targetSize => _targetSize;
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

  @override
  bool get sizedByParent => false;

  @override
  FollowerLayer? get layer => super.layer as FollowerLayer?;

  /// @nodoc
  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
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

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final linkedOffset = anchor.getSourceOffset(
      sourceSize: size,
      targetRect: Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
      overlayRect: const Rect.fromLTRB(
        // We don't know where we'll end up, so we have no idea what our cull rect should be.
        0,
        0,
        double.infinity,
        double.infinity,
      ),
    );

    if (layer == null) {
      layer = FollowerLayer(
        link: link,
        showWhenUnlinked: false,
        linkedOffset: linkedOffset,
      );
    } else {
      layer!
        ..link = link
        ..showWhenUnlinked = false
        ..linkedOffset = linkedOffset;
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
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));

    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
