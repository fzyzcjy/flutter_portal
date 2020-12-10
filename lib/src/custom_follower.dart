import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// @nodoc
class MyCompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// @nodoc
  const MyCompositedTransformFollower({
    Key? key,
    required this.link,
    required this.targetSize,
    required this.childAnchor,
    required this.portalAnchor,
    Widget? child,
  }) : super(key: key, child: child);

  /// @nodoc
  final Alignment childAnchor;

  /// @nodoc
  final Alignment portalAnchor;

  /// @nodoc
  final LayerLink link;

  /// @nodoc
  final Size targetSize;

  @override
  MyRenderFollowerLayer createRenderObject(BuildContext context) {
    return MyRenderFollowerLayer(
      childAnchor: childAnchor,
      portalAnchor: portalAnchor,
      link: link,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MyRenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..targetSize = targetSize
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Alignment>('childAnchor', childAnchor));
    properties.add(
      DiagnosticsProperty<Alignment>('portalAnchor', portalAnchor),
    );
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(DiagnosticsProperty<Size>('targetSize', targetSize));
  }
}

/// @nodoc
class MyRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  MyRenderFollowerLayer({
    required LayerLink link,
    required Size targetSize,
    required Alignment childAnchor,
    required Alignment portalAnchor,
    RenderBox? child,
  })  : _childAnchor = childAnchor,
        _portalAnchor = portalAnchor,
        _link = link,
        _targetSize = targetSize,
        super(child);

  Alignment _childAnchor;

  /// @nodoc
  Alignment get childAnchor => _childAnchor;
  set childAnchor(Alignment childAnchor) {
    if (childAnchor != _childAnchor) {
      _childAnchor = childAnchor;
      markNeedsPaint();
    }
  }

  Alignment _portalAnchor;

  /// @nodoc
  Alignment get portalAnchor => _portalAnchor;
  set portalAnchor(Alignment portalAnchor) {
    if (portalAnchor != _portalAnchor) {
      _portalAnchor = portalAnchor;
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
    final linkedOffset = childAnchor.withinRect(
          Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
        ) -
        portalAnchor.withinRect(Rect.fromLTWH(0, 0, size.width, size.height));

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

    properties.add(DiagnosticsProperty('childAnchor', childAnchor));
    properties.add(DiagnosticsProperty('portalAnchor', portalAnchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
