// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, curly_braces_in_flow_control_structures, omit_local_variable_types, comment_references, always_put_control_body_on_new_line

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../anchor.dart';
import 'rendering_layer.dart';

typedef TheaterGetter = RenderBox? Function();

/// @nodoc
class EnhancedRenderLeaderLayer extends RenderProxyBox {
  /// @nodoc
  EnhancedRenderLeaderLayer({
    required EnhancedLayerLink link,
    // NOTE MODIFIED some arguments
    required TheaterGetter theaterGetter,
    required String? debugName,
    RenderBox? child,
  })  : assert(link != null),
        _link = link,
        _theaterGetter = theaterGetter,
        _debugName = debugName,
        super(child);

  /// @nodoc
  EnhancedLayerLink get link => _link;
  EnhancedLayerLink _link;

  set link(EnhancedLayerLink value) {
    assert(value != null);
    if (_link == value) return;
    _link.leaderSize = null;
    _link = value;
    if (_previousLayoutSize != null) {
      _link.leaderSize = _previousLayoutSize;
    }
    markNeedsPaint();
  }

  /// @nodoc
  TheaterGetter get theaterGetter => _theaterGetter;
  TheaterGetter _theaterGetter;

  set theaterGetter(TheaterGetter value) {
    if (_theaterGetter == value) {
      return;
    }
    _theaterGetter = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  // The latest size of this [RenderBox], computed during the previous layout
  // pass. It should always be equal to [size], but can be accessed even when
  // [debugDoingThisResize] and [debugDoingThisLayout] are false.
  Size? _previousLayoutSize;

  // NOTE MODIFIED add
  String? get debugName => _debugName;
  String? _debugName;

  set debugName(String? value) {
    if (_debugName == value) return;
    _debugName = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    _previousLayoutSize = size;
    link.leaderSize = size;
  }

  // https://github.com/fzyzcjy/flutter_portal/issues/85
  late final _theaterShiftCache = _FrameCache<RenderBox, Offset>(
      (theater) => globalToLocal(Offset.zero, ancestor: theater));

  Rect _theaterRectRelativeToLeader() {
    assert(
      theaterGetter() != null,
      'The theater must be set in the OverlayLink when the '
      '_RenderPortalTheater is inserted as a child of the _CompositedTransformTheaterInfoScope. '
      'Therefore, it must not be null in any child PortalEntry.',
    );
    final theater = theaterGetter()!;

    // final shift = globalToLocal(Offset.zero, ancestor: theater);
    final shift = _theaterShiftCache.get(theater);

    return shift & theater.size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = EnhancedLeaderLayer(
        link: link,
        offset: offset,
        theaterRectRelativeToLeader: _theaterRectRelativeToLeader,
        debugName: debugName,
      );
    } else {
      final EnhancedLeaderLayer leaderLayer = layer! as EnhancedLeaderLayer;
      leaderLayer
        ..link = link
        ..offset = offset
        ..theaterRectRelativeToLeader = _theaterRectRelativeToLeader
        ..debugName = debugName;
    }
    context.pushLayer(layer!, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EnhancedLayerLink>('link', link));
    properties.add(DiagnosticsProperty('theaterGetter', theaterGetter));
    properties.add(DiagnosticsProperty('debugName', debugName));
  }
}

class _FrameCache<K extends Object, V extends Object> {
  _FrameCache(this._compute);

  final V Function(K) _compute;

  MapEntry<K, V>? _cache;

  V get(K key) {
    final cache = _cache;
    if (cache != null && cache.key == key) {
      assert(() {
        final value = _compute(key);
        assert(
          value == cache.value,
          '_FrameCache want to use cache, but the value indeed changes. '
          'key=$key value=$value cachedValue=${cache.value}',
        );
        return true;
      }());

      return cache.value;
    } else {
      final value = _compute(key);

      _cache = MapEntry(key, value);
      // clear cache after frame
      SchedulerBinding.instance.addPostFrameCallback((_) => _cache = null);

      return value;
    }
  }
}

/// @nodoc
class EnhancedRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  EnhancedRenderFollowerLayer({
    required EnhancedLayerLink link,
    required bool showWhenUnlinked,
    // NOTE MODIFIED some arguments
    required Size targetSize,
    required EnhancedCompositedTransformAnchor anchor,
    required String? debugName,
    RenderBox? child,
  })  : _anchor = anchor,
        _link = link,
        _showWhenUnlinked = showWhenUnlinked,
        _targetSize = targetSize,
        _debugName = debugName,
        super(child);

  /// @nodoc
  bool get showWhenUnlinked => _showWhenUnlinked;
  bool _showWhenUnlinked;

  set showWhenUnlinked(bool value) {
    assert(value != null);
    if (_showWhenUnlinked == value) return;
    _showWhenUnlinked = value;
    markNeedsPaint();
  }

  /// @nodoc
  EnhancedCompositedTransformAnchor get anchor => _anchor;
  EnhancedCompositedTransformAnchor _anchor;

  set anchor(EnhancedCompositedTransformAnchor value) {
    if (_anchor != value) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  /// @nodoc
  EnhancedLayerLink get link => _link;
  EnhancedLayerLink _link;

  set link(EnhancedLayerLink value) {
    if (_link == value) {
      return;
    }
    _link = value;
    markNeedsPaint();
  }

  /// @nodoc
  Size get targetSize => _targetSize;
  Size _targetSize;

  set targetSize(Size value) {
    if (_targetSize == value) {
      return;
    }
    _targetSize = value;
    markNeedsPaint();
  }

  // NOTE MODIFIED add
  String? get debugName => _debugName;
  String? _debugName;

  set debugName(String? value) {
    if (_debugName == value) return;
    _debugName = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  /// @nodoc
  @override
  EnhancedFollowerLayer? get layer => super.layer as EnhancedFollowerLayer?;

  /// @nodoc
  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Disables the hit testing if this render object is hidden.
    if (link.leader == null && !showWhenUnlinked) return false;
    // RenderFollowerLayer objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
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

  // NOTE MODIFIED added
  /// Returns the linked offset in relation to the leader layer.
  ///
  /// The [LeaderLayer] is inserted by the [CompositedTransformTarget] in
  /// [PortalTarget].
  ///
  /// The reason we cannot simply access the [link]'s leader in [paint] is that
  /// the leader is only attached to the [EnhancedLayerLink] in [LeaderLayer.attach],
  /// which is called in the compositing phase which is after the paint phase.
  Offset _computeLinkedOffset() {
    return anchor.getFollowerOffset(
      // The size is set in performLayout of the RenderProxyBoxMixin.
      followerSize: size,
      targetSize: targetSize,
      theaterRect: link.leader!.theaterRectRelativeToLeader(),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // NOTE MODIFIED removed original [effectiveLinkedOffset] calculation, and replace with callback

    if (layer == null) {
      layer = EnhancedFollowerLayer(
        link: link,
        showWhenUnlinked: showWhenUnlinked,
        linkedOffsetCallback: _computeLinkedOffset,
        unlinkedOffset: offset,
        debugName: debugName,
      );
    } else {
      layer
        ?..link = link
        ..showWhenUnlinked = showWhenUnlinked
        ..linkedOffsetCallback = _computeLinkedOffset
        ..unlinkedOffset = offset
        ..debugName = debugName;
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
    properties.add(DiagnosticsProperty<EnhancedLayerLink>('link', link));
    properties.add(DiagnosticsProperty('showWhenUnlinked', showWhenUnlinked));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
    properties.add(DiagnosticsProperty('debugName', debugName));
  }
}
