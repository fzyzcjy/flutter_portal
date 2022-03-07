// ignore_for_file: comment_references, unnecessary_null_comparison, curly_braces_in_flow_control_structures, prefer_int_literals, diagnostic_describe_all_properties, omit_local_variable_types, avoid_types_on_closure_parameters

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// An object that a [MyLeaderLayer] can register with.
///
/// An instance of this class should be provided as the [MyLeaderLayer.link] and
/// the [FollowerLayer.link] properties to cause the [FollowerLayer] to follow
/// the [MyLeaderLayer].
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that creates a [MyLeaderLayer].
///  * [CompositedTransformFollower], the widget that creates a [FollowerLayer].
///  * [RenderMyLeaderLayer] and [RenderFollowerLayer], the corresponding
///    render objects.
class MyLayerLink {
  /// The [MyLeaderLayer] connected to this link.
  MyLeaderLayer? get leader => _leader;
  MyLeaderLayer? _leader;

  void _registerLeader(MyLeaderLayer leader) {
    assert(_leader != leader);
    assert(() {
      if (_leader != null) {
        _debugPreviousLeaders ??= <MyLeaderLayer>{};
        _debugScheduleLeadersCleanUpCheck();
        return _debugPreviousLeaders!.add(_leader!);
      }
      return true;
    }());
    _leader = leader;
  }

  void _unregisterLeader(MyLeaderLayer leader) {
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
  Set<MyLeaderLayer>? _debugPreviousLeaders;
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

  /// The total size of the content of the connected [MyLeaderLayer].
  ///
  /// Generally this should be set by the [RenderObject] that paints on the
  /// registered [MyLeaderLayer] (for instance a [RenderMyLeaderLayer] that shares
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
class MyLeaderLayer extends ContainerLayer {
  /// Creates a leader layer.
  ///
  /// The [link] property must not be null, and must not have been provided to
  /// any other [MyLeaderLayer] layers that are [attached] to the layer tree at
  /// the same time.
  ///
  /// The [offset] property must be non-null before the compositing phase of the
  /// pipeline.
  MyLeaderLayer({required MyLayerLink link, Offset offset = Offset.zero})
      : assert(link != null),
        _link = link,
        _offset = offset;

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
        // NOTE XXX edit
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
    properties.add(DiagnosticsProperty<MyLayerLink>('link', link));
  }
}
