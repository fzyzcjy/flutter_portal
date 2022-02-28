import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

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
  _CustomFollowerLayer? get layer => super.layer as _CustomFollowerLayer?;

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

  /// Returns the linked offset in relation to the leader layer.
  ///
  /// The [LeaderLayer] is inserted by the [CompositedTransformTarget] in
  /// [PortalTarget].
  ///
  /// The reason we cannot simply access the [link]'s leader in [paint] is that
  /// the leader is only attached to the [LayerLink] in [LeaderLayer.attach],
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
    if (layer == null) {
      layer = _CustomFollowerLayer(
        link: link,
        linkedOffsetCallback: _computeLinkedOffset,
      );
    } else {
      layer!
        ..link = link
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
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties
        .add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));

    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}

/// A composited layer that applies a transformation matrix to its children such
/// that they are positioned based on the position of a [LeaderLayer] and some
/// extra computation performed by a callback.
///
/// Note that this is like [FollowerLayer] but instead of taking a
/// [FollowerLayer.linkedOffset], it takes a [linkedOffsetCallback] to compute
/// this offset.
///
/// This custom follower layer does not do anything if unlinked (equal to
/// [FollowerLayer.unlinkedOffset] being [Offset.zero]).
///
/// For documentation of undocumented code, see [FollowerLayer].
class _CustomFollowerLayer extends ContainerLayer {
  /// Creates a follower layer.
  ///
  /// The [link] property must not be null.
  _CustomFollowerLayer({
    required this.link,
    required this.linkedOffsetCallback,
  });

  LayerLink link;

  /// Callback that is called to compute the linked offset of the follower layer
  /// based on the `leaderOffset` of the leader layer.
  ///
  /// This is like [FollowerLayer.linkedOffset] but as a callback. Note that
  /// this has the *exact* function of [FollowerLayer.linkedOffset] and
  /// therefore the leader layer offset does not need to be added to the
  /// returned offset. The returned offset should only be the offset from the
  /// leader layer.
  /// The `leaderOffset` is only passed in case it needs to be used inside of
  /// the callback for computation reasons.
  Offset Function(Offset leaderOffset) linkedOffsetCallback;

  Offset? _lastOffset;
  Matrix4? _lastTransform;
  Matrix4? _invertedTransform;
  bool _inverseDirty = true;

  Offset? _transformOffset(Offset localPosition) {
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(getLastTransform()!);
      _inverseDirty = false;
    }
    if (_invertedTransform == null) {
      return null;
    }
    final vector = Vector4(localPosition.dx, localPosition.dy, 0, 1);
    final result = _invertedTransform!.transform(vector);
    // We know the link leader cannot be null since we return early in
    // findAnnotations otherwise.
    final linkedOffset = linkedOffsetCallback(link.leader!.offset);
    return Offset(result[0] - linkedOffset.dx, result[1] - linkedOffset.dy);
  }

  @override
  bool findAnnotations<S extends Object>(
      AnnotationResult<S> result, Offset localPosition,
      {required bool onlyFirst}) {
    if (link.leader == null) {
      return false;
    }
    final transformedOffset = _transformOffset(localPosition);
    if (transformedOffset == null) {
      return false;
    }
    return super
        .findAnnotations<S>(result, transformedOffset, onlyFirst: onlyFirst);
  }

  Matrix4? getLastTransform() {
    if (_lastTransform == null) {
      return null;
    }
    final result =
        Matrix4.translationValues(-_lastOffset!.dx, -_lastOffset!.dy, 0);
    result.multiply(_lastTransform!);
    return result;
  }

  static Matrix4 _collectTransformForLayerChain(List<ContainerLayer?> layers) {
    // Initialize our result matrix.
    final result = Matrix4.identity();
    // Apply each layer to the matrix in turn, starting from the last layer,
    // and providing the previous layer as the child.
    for (var index = layers.length - 1; index > 0; index -= 1) {
      layers[index]?.applyTransform(layers[index - 1], result);
    }
    return result;
  }

  static Layer? _pathsToCommonAncestor(
    Layer? a,
    Layer? b,
    List<ContainerLayer?> ancestorsA,
    List<ContainerLayer?> ancestorsB,
  ) {
    // No common ancestor found.
    if (a == null || b == null) {
      return null;
    }

    if (identical(a, b)) {
      return a;
    }

    if (a.depth < b.depth) {
      ancestorsB.add(b.parent);
      return _pathsToCommonAncestor(a, b.parent, ancestorsA, ancestorsB);
    } else if (a.depth > b.depth) {
      ancestorsA.add(a.parent);
      return _pathsToCommonAncestor(a.parent, b, ancestorsA, ancestorsB);
    }

    ancestorsA.add(a.parent);
    ancestorsB.add(b.parent);
    return _pathsToCommonAncestor(a.parent, b.parent, ancestorsA, ancestorsB);
  }

  void _establishTransform() {
    _lastTransform = null;
    final leader = link.leader;
    // Check to see if we are linked.
    if (leader == null) {
      return;
    }
    // If we're linked, check the link is valid.
    assert(
      leader.owner == owner,
      'Linked LeaderLayer anchor is not in the same layer tree as the FollowerLayer.',
    );

    // Stores [leader, ..., commonAncestor] after calling _pathsToCommonAncestor.
    final List<ContainerLayer?> forwardLayers = <ContainerLayer>[leader];
    // Stores [this (follower), ..., commonAncestor] after calling
    // _pathsToCommonAncestor.
    final List<ContainerLayer?> inverseLayers = <ContainerLayer>[this];

    final ancestor = _pathsToCommonAncestor(
      leader,
      this,
      forwardLayers,
      inverseLayers,
    );
    assert(ancestor != null);

    final forwardTransform = _collectTransformForLayerChain(forwardLayers);
    // Further transforms the coordinate system to a hypothetical child (null)
    // of the leader layer, to account for the leader's additional paint offset
    // and layer offset (LeaderLayer._lastOffset).
    leader.applyTransform(null, forwardTransform);
    final linkedOffset = linkedOffsetCallback(leader.offset);
    forwardTransform.translate(linkedOffset.dx, linkedOffset.dy);

    final inverseTransform = _collectTransformForLayerChain(inverseLayers);

    if (inverseTransform.invert() == 0.0) {
      // We are in a degenerate transform, so there's not much we can do.
      return;
    }
    // Combine the matrices and store the result.
    inverseTransform.multiply(forwardTransform);
    _lastTransform = inverseTransform;
    _inverseDirty = true;
  }

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    if (link.leader == null) {
      _lastTransform = null;
      _lastOffset = null;
      _inverseDirty = true;
      engineLayer = null;
      return;
    }
    _establishTransform();
    if (_lastTransform != null) {
      engineLayer = builder.pushTransform(
        _lastTransform!.storage,
        oldLayer: engineLayer as TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = layerOffset;
    } else {
      _lastOffset = null;
      final matrix = Matrix4.translationValues(0, 0, 0);
      engineLayer = builder.pushTransform(
        matrix.storage,
        oldLayer: engineLayer as TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
    }
    _inverseDirty = true;
  }

  @override
  void applyTransform(Layer? child, Matrix4 transform) {
    assert(child != null);
    if (_lastTransform != null) {
      transform.multiply(_lastTransform!);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(
        TransformProperty('transform', getLastTransform(), defaultValue: null));
    properties.add(DiagnosticsProperty<Offset Function(Offset leaderOffset)>(
      'linkedOffsetCallback',
      linkedOffsetCallback,
    ));
  }
}
