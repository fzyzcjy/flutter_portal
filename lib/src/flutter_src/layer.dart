// ignore_for_file: comment_references, unnecessary_null_comparison, curly_braces_in_flow_control_structures, prefer_int_literals, diagnostic_describe_all_properties, omit_local_variable_types

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

/// An object that a [MyLeaderLayer] can register with.
///
/// An instance of this class should be provided as the [MyLeaderLayer.link] and
/// the [MyFollowerLayer.link] properties to cause the [MyFollowerLayer] to follow
/// the [MyLeaderLayer].
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that creates a [MyLeaderLayer].
///  * [CompositedTransformFollower], the widget that creates a [MyFollowerLayer].
///  * [RenderLeaderLayer] and [RenderFollowerLayer], the corresponding
///    render objects.
class MyLayerLink {
  MyLeaderLayer? _leader;

  int _connectedFollowers = 0;

  /// Whether a [MyLeaderLayer] is currently connected to this link.
  bool get leaderConnected => _leader != null;

  /// Called by the [MyFollowerLayer] to establish a link to a [MyLeaderLayer].
  ///
  /// The returned [LayerLinkHandle] provides access to the leader via
  /// [LayerLinkHandle.leader].
  ///
  /// When the [MyFollowerLayer] no longer wants to follow the [MyLeaderLayer],
  /// [LayerLinkHandle.dispose] must be called to disconnect the link.
  _MyLayerLinkHandle _registerFollower() {
    assert(_connectedFollowers >= 0);
    _connectedFollowers++;
    return _MyLayerLinkHandle(this);
  }

  /// Returns the [MyLeaderLayer] currently connected to this link.
  ///
  /// Valid in debug mode only. Returns null in all other modes.
  MyLeaderLayer? get debugLeader {
    MyLeaderLayer? result;
    if (kDebugMode) {
      result = _leader;
    }
    return result;
  }

  /// The total size of the content of the connected [MyLeaderLayer].
  ///
  /// Generally this should be set by the [RenderObject] that paints on the
  /// registered [MyLeaderLayer] (for instance a [RenderLeaderLayer] that shares
  /// this link with its followers). This size may be outdated before and during
  /// layout.
  Size? leaderSize;

  @override
  String toString() => '${describeIdentity(this)}(${ _leader != null ? "<linked>" : "<dangling>" })';
}

/// A handle provided by [MyLayerLink.registerFollower] to a calling
/// [MyFollowerLayer] to establish a link between that [MyFollowerLayer] and a
/// [MyLeaderLayer].
///
/// If the link is no longer needed, [dispose] must be called to disconnect it.
class _MyLayerLinkHandle {
  _MyLayerLinkHandle(this._link);

  MyLayerLink? _link;

  /// The currently-registered [MyLeaderLayer], if any.
  MyLeaderLayer? get leader => _link!._leader;

  /// Disconnects the link between the [MyFollowerLayer] owning this handle and
  /// the [leader].
  ///
  /// The [LayerLinkHandle] becomes unusable after calling this method.
  void dispose() {
    assert(_link!._connectedFollowers > 0);
    _link!._connectedFollowers--;
    _link = null;
  }
}

/// A composited layer that can be followed by a [MyFollowerLayer].
///
/// This layer collapses the accumulated offset into a transform and passes
/// [Offset.zero] to its child layers in the [addToScene]/[addChildrenToScene]
/// methods, so that [applyTransform] will work reliably.
class MyLeaderLayer extends ContainerLayer {
  /// Creates a leader layer.
  ///
  /// The [link] property must not be null, and must not have been provided to
  /// any other [MyLeaderLayer] layers that are [attached] to the layer tree at
  /// the same time.
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  MyLeaderLayer({ required MyLayerLink link, Offset offset = Offset.zero }) : assert(link != null), _link = link, _offset = offset;

  /// The object with which this layer should register.
  ///
  /// The link will be established when this layer is [attach]ed, and will be
  /// cleared when this layer is [detach]ed.
  MyLayerLink get link => _link;
  MyLayerLink _link;
  set link(MyLayerLink value) {
    assert(value != null);
    if (_link == value) {
      return;
    }
    _link._leader = null;
    _link = value;
  }

  /// Offset from parent in the parent's coordinate system.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    assert(value != null);
    if (value == _offset) {
      return;
    }
    _offset = value;
    if (!alwaysNeedsAddToScene) {
      markNeedsAddToScene();
    }
  }

  /// {@macro flutter.rendering.MyFollowerLayer.alwaysNeedsAddToScene}
  @override
  bool get alwaysNeedsAddToScene => _link._connectedFollowers > 0;

  @override
  void attach(Object owner) {
    super.attach(owner);
    assert(link._leader == null);
    _lastOffset = null;
    link._leader = this;
  }

  @override
  void detach() {
    assert(link._leader == this);
    link._leader = null;
    _lastOffset = null;
    super.detach();
  }

  /// The offset the last time this layer was composited.
  ///
  /// This is reset to null when the layer is attached or detached, to help
  /// catch cases where the follower layer ends up before the leader layer, but
  /// not every case can be detected.
  Offset? _lastOffset;

  @override
  bool findAnnotations<S extends Object>(AnnotationResult<S> result, Offset localPosition, { required bool onlyFirst }) {
    return super.findAnnotations<S>(result, localPosition - offset, onlyFirst: onlyFirst);
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    assert(offset != null);
    _lastOffset = offset;
    if (_lastOffset != Offset.zero)
      engineLayer = builder.pushTransform(
        Matrix4.translationValues(_lastOffset!.dx, _lastOffset!.dy, 0.0).storage,
        // NOTE XXX _engineLayer -> engineLayer
        oldLayer: engineLayer as ui.TransformEngineLayer?,
      );
    addChildrenToScene(builder);
    if (_lastOffset != Offset.zero)
      builder.pop();
  }

  /// Applies the transform that would be applied when compositing the given
  /// child to the given matrix.
  ///
  /// See [ContainerLayer.applyTransform] for details.
  ///
  /// The `child` argument may be null, as the same transform is applied to all
  /// children.
  @override
  void applyTransform(Layer? child, Matrix4 transform) {
    assert(_lastOffset != null);
    if (_lastOffset != Offset.zero)
      transform.translate(_lastOffset!.dx, _lastOffset!.dy);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(DiagnosticsProperty<MyLayerLink>('link', link));
  }
}

/// A composited layer that applies a transformation matrix to its children such
/// that they are positioned to match a [MyLeaderLayer].
///
/// If any of the ancestors of this layer have a degenerate matrix (e.g. scaling
/// by zero), then the [MyFollowerLayer] will not be able to transform its child
/// to the coordinate space of the [MyLeaderLayer].
///
/// A [linkedOffset] property can be provided to further offset the child layer
/// from the leader layer, for example if the child is to follow the linked
/// layer at a distance rather than directly overlapping it.
class MyFollowerLayer extends ContainerLayer {
  /// Creates a follower layer.
  ///
  /// The [link] property must not be null.
  ///
  /// The [unlinkedOffset], [linkedOffset], and [showWhenUnlinked] properties
  /// must be non-null before the compositing phase of the pipeline.
  MyFollowerLayer({
    required MyLayerLink link,
    this.showWhenUnlinked = true,
    this.unlinkedOffset = Offset.zero,
    this.linkedOffset = Offset.zero,
  }) : assert(link != null), _link = link;

  /// The link to the [MyLeaderLayer].
  ///
  /// The same object should be provided to a [MyLeaderLayer] that is earlier in
  /// the layer tree. When this layer is composited, it will apply a transform
  /// that moves its children to match the position of the [MyLeaderLayer].
  MyLayerLink get link => _link;
  set link(MyLayerLink value) {
    assert(value != null);
    if (value != _link && _leaderHandle != null) {
      _leaderHandle!.dispose();
      _leaderHandle = value._registerFollower();
    }
    _link = value;
  }
  MyLayerLink _link;

  /// Whether to show the layer's contents when the [link] does not point to a
  /// [MyLeaderLayer].
  ///
  /// When the layer is linked, children layers are positioned such that they
  /// have the same global position as the linked [MyLeaderLayer].
  ///
  /// When the layer is not linked, then: if [showWhenUnlinked] is true,
  /// children are positioned as if the [MyFollowerLayer] was a [ContainerLayer];
  /// if it is false, then children are hidden.
  ///
  /// The [showWhenUnlinked] property must be non-null before the compositing
  /// phase of the pipeline.
  bool? showWhenUnlinked;

  /// Offset from parent in the parent's coordinate system, used when the layer
  /// is not linked to a [MyLeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [unlinkedOffset] property must be non-null before the compositing
  /// phase of the pipeline.
  ///
  /// See also:
  ///
  ///  * [linkedOffset], for when the layers are linked.
  Offset? unlinkedOffset;

  /// Offset from the origin of the leader layer to the origin of the child
  /// layers, used when the layer is linked to a [MyLeaderLayer].
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  ///
  /// The [linkedOffset] property must be non-null before the compositing phase
  /// of the pipeline.
  ///
  /// See also:
  ///
  ///  * [unlinkedOffset], for when the layer is not linked.
  Offset? linkedOffset;

  _MyLayerLinkHandle? _leaderHandle;

  @override
  void attach(Object owner) {
    super.attach(owner);
    _leaderHandle = _link._registerFollower();
  }

  @override
  void detach() {
    super.detach();
    _leaderHandle?.dispose();
    _leaderHandle = null;
  }

  Offset? _lastOffset;
  Matrix4? _lastTransform;
  Matrix4? _invertedTransform;
  bool _inverseDirty = true;

  Offset? _transformOffset(Offset localPosition) {
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(getLastTransform()!);
      _inverseDirty = false;
    }
    if (_invertedTransform == null)
      return null;
    final Vector4 vector = Vector4(localPosition.dx, localPosition.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform!.transform(vector);
    return Offset(result[0] - linkedOffset!.dx, result[1] - linkedOffset!.dy);
  }

  @override
  bool findAnnotations<S extends Object>(AnnotationResult<S> result, Offset localPosition, { required bool onlyFirst }) {
    if (_leaderHandle!.leader == null) {
      if (showWhenUnlinked!) {
        return super.findAnnotations(result, localPosition - unlinkedOffset!, onlyFirst: onlyFirst);
      }
      return false;
    }
    final Offset? transformedOffset = _transformOffset(localPosition);
    if (transformedOffset == null) {
      return false;
    }
    return super.findAnnotations<S>(result, transformedOffset, onlyFirst: onlyFirst);
  }

  /// The transform that was used during the last composition phase.
  ///
  /// If the [link] was not linked to a [MyLeaderLayer], or if this layer has
  /// a degenerate matrix applied, then this will be null.
  ///
  /// This method returns a new [Matrix4] instance each time it is invoked.
  Matrix4? getLastTransform() {
    if (_lastTransform == null)
      return null;
    final Matrix4 result = Matrix4.translationValues(-_lastOffset!.dx, -_lastOffset!.dy, 0.0);
    result.multiply(_lastTransform!);
    return result;
  }

  /// Call [applyTransform] for each layer in the provided list.
  ///
  /// The list is in reverse order (deepest first). The first layer will be
  /// treated as the child of the second, and so forth. The first layer in the
  /// list won't have [applyTransform] called on it. The first layer may be
  /// null.
  static Matrix4 _collectTransformForLayerChain(List<ContainerLayer?> layers) {
    // Initialize our result matrix.
    final Matrix4 result = Matrix4.identity();
    // Apply each layer to the matrix in turn, starting from the last layer,
    // and providing the previous layer as the child.
    for (int index = layers.length - 1; index > 0; index -= 1)
      layers[index]?.applyTransform(layers[index - 1], result);
    return result;
  }

  /// Find the common ancestor of two layers [a] and [b] by searching towards
  /// the root of the tree, and append each ancestor of [a] or [b] visited along
  /// the path to [ancestorsA] and [ancestorsB] respectively.
  ///
  /// Returns null if [a] [b] do not share a common ancestor, in which case the
  /// results in [ancestorsA] and [ancestorsB] are undefined.
  static Layer? _pathsToCommonAncestor(
      Layer? a,
      Layer? b,
      List<ContainerLayer?> ancestorsA,
      List<ContainerLayer?> ancestorsB,
      ) {
    // No common ancestor found.
    if (a == null || b == null)
      return null;

    if (identical(a, b))
      return a;

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

  /// Populate [_lastTransform] given the current state of the tree.
  void _establishTransform() {
    assert(link != null);
    _lastTransform = null;
    final MyLeaderLayer? leader = _leaderHandle!.leader;
    // Check to see if we are linked.
    if (leader == null)
      return;
    // If we're linked, check the link is valid.
    assert(
    leader.owner == owner,
    'Linked MyLeaderLayer anchor is not in the same layer tree as the MyFollowerLayer.',
    );
    assert(
    leader._lastOffset != null,
    'MyLeaderLayer anchor must come before MyFollowerLayer in paint order, but the reverse was true.',
    );

    // Stores [leader, ..., commonAncestor] after calling _pathsToCommonAncestor.
    final List<ContainerLayer?> forwardLayers = <ContainerLayer>[leader];
    // Stores [this (follower), ..., commonAncestor] after calling
    // _pathsToCommonAncestor.
    final List<ContainerLayer?> inverseLayers = <ContainerLayer>[this];

    final Layer? ancestor = _pathsToCommonAncestor(
      leader, this,
      forwardLayers, inverseLayers,
    );
    assert(ancestor != null);

    final Matrix4 forwardTransform = _collectTransformForLayerChain(forwardLayers);
    // Further transforms the coordinate system to a hypothetical child (null)
    // of the leader layer, to account for the leader's additional paint offset
    // and layer offset (MyLeaderLayer._lastOffset).
    leader.applyTransform(null, forwardTransform);
    forwardTransform.translate(linkedOffset!.dx, linkedOffset!.dy);

    final Matrix4 inverseTransform = _collectTransformForLayerChain(inverseLayers);

    if (inverseTransform.invert() == 0.0) {
      // We are in a degenerate transform, so there's not much we can do.
      return;
    }
    // Combine the matrices and store the result.
    inverseTransform.multiply(forwardTransform);
    _lastTransform = inverseTransform;
    _inverseDirty = true;
  }

  /// {@template flutter.rendering.MyFollowerLayer.alwaysNeedsAddToScene}
  /// This disables retained rendering.
  ///
  /// A [MyFollowerLayer] copies changes from a [MyLeaderLayer] that could be anywhere
  /// in the Layer tree, and that leader layer could change without notifying the
  /// follower layer. Therefore we have to always call a follower layer's
  /// [addToScene]. In order to call follower layer's [addToScene], leader layer's
  /// [addToScene] must be called first so leader layer must also be considered
  /// as [alwaysNeedsAddToScene].
  /// {@endtemplate}
  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    assert(link != null);
    assert(showWhenUnlinked != null);
    if (_leaderHandle!.leader == null && !showWhenUnlinked!) {
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
        // NOTE XXX _engineLayer -> engineLayer
        oldLayer: engineLayer as ui.TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = unlinkedOffset;
    } else {
      _lastOffset = null;
      final Matrix4 matrix = Matrix4.translationValues(unlinkedOffset!.dx, unlinkedOffset!.dy, .0);
      engineLayer = builder.pushTransform(
        matrix.storage,
        // NOTE XXX _engineLayer -> engineLayer
        oldLayer: engineLayer as ui.TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
    }
    _inverseDirty = true;
  }

  @override
  void applyTransform(Layer? child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    if (_lastTransform != null) {
      transform.multiply(_lastTransform!);
    } else {
      transform.multiply(Matrix4.translationValues(unlinkedOffset!.dx, unlinkedOffset!.dy, 0));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MyLayerLink>('link', link));
    properties.add(TransformProperty('transform', getLastTransform(), defaultValue: null));
  }
}
