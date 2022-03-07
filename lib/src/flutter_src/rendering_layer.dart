// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: comment_references, unnecessary_null_comparison, curly_braces_in_flow_control_structures, prefer_int_literals, diagnostic_describe_all_properties, omit_local_variable_types, avoid_types_on_closure_parameters, always_put_control_body_on_new_line

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

/// An object that a [CustomLeaderLayer] can register with.
///
/// An instance of this class should be provided as the [CustomLeaderLayer.link] and
/// the [FollowerLayer.link] properties to cause the [FollowerLayer] to follow
/// the [CustomLeaderLayer].
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that creates a [CustomLeaderLayer].
///  * [CompositedTransformFollower], the widget that creates a [FollowerLayer].
///  * [RenderCustomLeaderLayer] and [RenderFollowerLayer], the corresponding
///    render objects.
class CustomLayerLink {
  /// The [CustomLeaderLayer] connected to this link.
  CustomLeaderLayer? get leader => _leader;
  CustomLeaderLayer? _leader;

  void _registerLeader(CustomLeaderLayer leader) {
    assert(_leader != leader);
    assert(() {
      if (_leader != null) {
        _debugPreviousLeaders ??= <CustomLeaderLayer>{};
        _debugScheduleLeadersCleanUpCheck();
        return _debugPreviousLeaders!.add(_leader!);
      }
      return true;
    }());
    _leader = leader;
  }

  void _unregisterLeader(CustomLeaderLayer leader) {
    if (_leader == leader) {
      _leader = null;
    } else {
      assert(_debugPreviousLeaders!.remove(leader));
    }
  }

  /// Stores the previous leaders that were replaced by the current [_leader]
  /// in the current frame.
  ///
  /// These leaders need to give up their leaderships of this link by the end of
  /// the current frame.
  Set<CustomLeaderLayer>? _debugPreviousLeaders;
  bool _debugLeaderCheckScheduled = false;

  /// Schedules the check as post frame callback to make sure the
  /// [_debugPreviousLeaders] is empty.
  void _debugScheduleLeadersCleanUpCheck() {
    assert(_debugPreviousLeaders != null);
    assert(() {
      if (_debugLeaderCheckScheduled) return true;
      _debugLeaderCheckScheduled = true;
      SchedulerBinding.instance!.addPostFrameCallback((Duration timeStamp) {
        _debugLeaderCheckScheduled = false;
        assert(_debugPreviousLeaders!.isEmpty);
      });
      return true;
    }());
  }

  /// The total size of the content of the connected [CustomLeaderLayer].
  ///
  /// Generally this should be set by the [RenderObject] that paints on the
  /// registered [CustomLeaderLayer] (for instance a [RenderCustomLeaderLayer] that shares
  /// this link with its followers). This size may be outdated before and during
  /// layout.
  Size? leaderSize;

  @override
  String toString() =>
      '${describeIdentity(this)}(${_leader != null ? "<linked>" : "<dangling>"})';
}

/// A composited layer that can be followed by a [FollowerLayer].
///
/// This layer collapses the accumulated offset into a transform and passes
/// [Offset.zero] to its child layers in the [addToScene]/[addChildrenToScene]
/// methods, so that [applyTransform] will work reliably.
class CustomLeaderLayer extends ContainerLayer {
  /// Creates a leader layer.
  ///
  /// The [link] property must not be null, and must not have been provided to
  /// any other [CustomLeaderLayer] layers that are [attached] to the layer tree at
  /// the same time.
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  CustomLeaderLayer(
      {required CustomLayerLink link, Offset offset = Offset.zero})
      : assert(link != null),
        _link = link,
        _offset = offset;

  /// The object with which this layer should register.
  ///
  /// The link will be established when this layer is [attach]ed, and will be
  /// cleared when this layer is [detach]ed.
  CustomLayerLink get link => _link;
  CustomLayerLink _link;
  set link(CustomLayerLink value) {
    assert(value != null);
    if (_link == value) {
      return;
    }
    if (attached) {
      _link._unregisterLeader(this);
      value._registerLeader(this);
    }
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

  @override
  void attach(Object owner) {
    super.attach(owner);
    _link._registerLeader(this);
  }

  @override
  void detach() {
    _link._unregisterLeader(this);
    super.detach();
  }

  @override
  bool findAnnotations<S extends Object>(
      AnnotationResult<S> result, Offset localPosition,
      {required bool onlyFirst}) {
    return super.findAnnotations<S>(result, localPosition - offset,
        onlyFirst: onlyFirst);
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    assert(offset != null);
    if (offset != Offset.zero)
      engineLayer = builder.pushTransform(
        Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage,
        // NOTE MODIFIED from `_engineLayer` to `engineLayer`
        oldLayer: engineLayer as ui.TransformEngineLayer?,
      );
    addChildrenToScene(builder);
    if (offset != Offset.zero) builder.pop();
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
    if (offset != Offset.zero) transform.translate(offset.dx, offset.dy);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
  }
}

// NOTE MODIFIED the comments
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
class CustomFollowerLayer extends ContainerLayer {
  // NOTE MODIFIED the comments
  /// Creates a follower layer.
  ///
  /// The [link] property must not be null.
  CustomFollowerLayer({
    required this.link,
    // NOTE MODIFIED add [linkedOffsetCallback], remove several arguments like
    // [showWhenUnlinked], [unlinkedOffset], [linkedOffset]
    required this.linkedOffsetCallback,
  });

  CustomLayerLink link;

  // NOTE MODIFIED added this field
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

  // NOTE MODIFIED original Flutter code lets user pass it in as an argument,
  // but we just make it a constant zero.
  static const unlinkedOffset = Offset.zero;
  // NOTE MODIFIED similarly, make [showWhenUnlinked] a const for our needs.
  static const showWhenUnlinked = false;

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
    // NOTE MODIFIED compute [linkedOffset] by callback, instead of using a field
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
      if (showWhenUnlinked) {
        return super.findAnnotations(result, localPosition - unlinkedOffset,
            onlyFirst: onlyFirst);
      }
      return false;
    }
    final transformedOffset = _transformOffset(localPosition);
    if (transformedOffset == null) {
      return false;
    }
    return super
        .findAnnotations<S>(result, transformedOffset, onlyFirst: onlyFirst);
  }

  /// The transform that was used during the last composition phase.
  ///
  /// If the [link] was not linked to a [LeaderLayer], or if this layer has
  /// a degenerate matrix applied, then this will be null.
  ///
  /// This method returns a new [Matrix4] instance each time it is invoked.
  Matrix4? getLastTransform() {
    if (_lastTransform == null) {
      return null;
    }
    final result =
    Matrix4.translationValues(-_lastOffset!.dx, -_lastOffset!.dy, 0);
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
    final result = Matrix4.identity();
    // Apply each layer to the matrix in turn, starting from the last layer,
    // and providing the previous layer as the child.
    for (var index = layers.length - 1; index > 0; index -= 1) {
      layers[index]?.applyTransform(layers[index - 1], result);
    }
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

  bool _debugCheckLeaderBeforeFollower(
      List<ContainerLayer> leaderToCommonAncestor,
      List<ContainerLayer> followerToCommonAncestor,
      ) {
    if (followerToCommonAncestor.length <= 1) {
      // Follower is the common ancestor, ergo the leader must come AFTER the follower.
      return false;
    }
    if (leaderToCommonAncestor.length <= 1) {
      // Leader is the common ancestor, ergo the leader must come BEFORE the follower.
      return true;
    }

    // Common ancestor is neither the leader nor the follower.
    final leaderSubtreeBelowAncestor =
    leaderToCommonAncestor[leaderToCommonAncestor.length - 2];
    final followerSubtreeBelowAncestor =
    followerToCommonAncestor[followerToCommonAncestor.length - 2];

    Layer? sibling = leaderSubtreeBelowAncestor;
    while (sibling != null) {
      if (sibling == followerSubtreeBelowAncestor) {
        return true;
      }
      sibling = sibling.nextSibling;
    }
    // The follower subtree didn't come after the leader subtree.
    return false;
  }

  /// Populate [_lastTransform] given the current state of the tree.
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
    final forwardLayers = <ContainerLayer>[leader];
    // Stores [this (follower), ..., commonAncestor] after calling
    // _pathsToCommonAncestor.
    final inverseLayers = <ContainerLayer>[this];

    final ancestor = _pathsToCommonAncestor(
      leader,
      this,
      forwardLayers,
      inverseLayers,
    );
    assert(
    ancestor != null,
    'LeaderLayer and FollowerLayer do not have a common ancestor.',
    );
    assert(
    _debugCheckLeaderBeforeFollower(forwardLayers, inverseLayers),
    'LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.',
    );

    final forwardTransform = _collectTransformForLayerChain(forwardLayers);
    // Further transforms the coordinate system to a hypothetical child (null)
    // of the leader layer, to account for the leader's additional paint offset
    // and layer offset (LeaderLayer._lastOffset).
    leader.applyTransform(null, forwardTransform);
    // NOTE MODIFIED compute the [linkedOffset] by callback
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

  /// {@template flutter.rendering.FollowerLayer.alwaysNeedsAddToScene}
  /// This disables retained rendering.
  ///
  /// A [FollowerLayer] copies changes from a [LeaderLayer] that could be anywhere
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
    if (link.leader == null && !showWhenUnlinked) {
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
        // NOTE MODIFIED [_engineLayer] to [engineLayer]
        oldLayer: engineLayer as ui.TransformEngineLayer?,
      );
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = unlinkedOffset;
    } else {
      _lastOffset = null;
      final matrix =
      Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, 0);
      engineLayer = builder.pushTransform(
        matrix.storage,
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
    if (_lastTransform != null) {
      transform.multiply(_lastTransform!);
    } else {
      transform.multiply(
          Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, 0));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
    properties.add(
        TransformProperty('transform', getLastTransform(), defaultValue: null));
    // NOTE MODIFIED
    properties.add(DiagnosticsProperty<Offset Function(Offset leaderOffset)>(
      'linkedOffsetCallback',
      linkedOffsetCallback,
    ));
  }
}
