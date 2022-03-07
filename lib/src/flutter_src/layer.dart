// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: comment_references, unnecessary_null_comparison, curly_braces_in_flow_control_structures, prefer_int_literals, diagnostic_describe_all_properties, omit_local_variable_types, avoid_types_on_closure_parameters, always_put_control_body_on_new_line

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../anchor.dart';
import '../portal.dart';
import 'proxy_box.dart';

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
  CustomLeaderLayer({required CustomLayerLink link, Offset offset = Offset.zero})
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

/// @nodoc
@visibleForTesting
class CustomRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderFollowerLayer({
    required CustomLayerLink link,
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

  CustomLayerLink _link;

  /// @nodoc
  CustomLayerLink get link => _link;

  set link(CustomLayerLink value) {
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
  CustomFollowerLayer? get layer => super.layer as CustomFollowerLayer?;

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
  /// the leader is only attached to the [CustomLayerLink] in [LeaderLayer.attach],
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
      layer = CustomFollowerLayer(
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
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
    properties
        .add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));

    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
