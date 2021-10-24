import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'anchor.dart';
import 'portal.dart';

/// @nodoc
class CustomCompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// @nodoc
  const CustomCompositedTransformFollower({
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
  CustomRenderFollowerLayer createRenderObject(BuildContext context) {
    return CustomRenderFollowerLayer(
      anchor: anchor,
      link: link,
      overlayLink: overlayLink,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    CustomRenderFollowerLayer renderObject,
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
    properties
        .add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink));
    properties.add(DiagnosticsProperty<Size>('targetSize', targetSize));
  }
}

/// @nodoc
@visibleForTesting
class CustomRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderFollowerLayer({
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
  void paint(PaintingContext context, Offset offset) {
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
    final theaterShift = -localToGlobal(
      // We know that the leader is not null at this point because of our
      // CompositedTransformTarget implementation that ensures the leader is set
      // in the paint call of CustomRenderTargetLayer.
      link.leader!.offset,
    );
    final theaterRect = theaterShift & theater.size;
    final linkedOffset = anchor.getSourceOffset(
      // The size is set in performLayout of the RenderProxyBoxMixin.
      sourceSize: size,
      targetRect: Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
      theaterRect: theaterRect,
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
    properties
        .add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));

    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
