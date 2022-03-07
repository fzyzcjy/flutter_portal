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
  // NOTE XXX add
  MyLeaderLayer? get leader => _leader;

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
