// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, curly_braces_in_flow_control_structures, omit_local_variable_types, comment_references, always_put_control_body_on_new_line

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:common_flutter/utils/debug.dart';

import '../anchor.dart';
import '../portal_link.dart';
import 'rendering_layer.dart';

/// @nodoc
class CustomRenderLeaderLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderLeaderLayer({
    required CustomLayerLink link,
    // NOTE MODIFIED some arguments
    required PortalLink portalLink,
    required String? debugLabel,
    RenderBox? child,
  })  : assert(link != null),
        _link = link,
        _portalLink = portalLink,
        _debugLabel = debugLabel,
        super(child);

  /// @nodoc
  CustomLayerLink get link => _link;
  CustomLayerLink _link;
  set link(CustomLayerLink value) {
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
  PortalLink get portalLink => _portalLink;
  PortalLink _portalLink;

  set portalLink(PortalLink value) {
    if (_portalLink == value) {
      return;
    }
    _portalLink = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  // The latest size of this [RenderBox], computed during the previous layout
  // pass. It should always be equal to [size], but can be accessed even when
  // [debugDoingThisResize] and [debugDoingThisLayout] are false.
  Size? _previousLayoutSize;

  // NOTE MODIFIED add
  String? get debugLabel => _debugLabel;
  String? _debugLabel;
  set debugLabel(String? value) {
    if (_debugLabel == value) return;
    _debugLabel = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    _previousLayoutSize = size;
    link.leaderSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final theater = portalLink.theater!;
    final portalTheaterToLeaderOffset =
        globalToLocal(Offset.zero, ancestor: theater);

    print('hi CustomRenderLeaderLayer paint ($debugLabel) offset=$offset '
        'offset-relative-to-theater=${globalToLocal(offset, ancestor: theater)} '
        'this.globalToLocal(Offset.zero, ancestor: portalLink.theater!)=${this.globalToLocal(Offset.zero, ancestor: theater)}');

    if (layer == null) {
      layer = CustomLeaderLayer(
        link: link,
        offset: offset,
        portalTheaterToLeaderOffset: portalTheaterToLeaderOffset,
        debugLabel: debugLabel,
      );
    } else {
      final CustomLeaderLayer leaderLayer = layer! as CustomLeaderLayer;
      leaderLayer
        ..link = link
        ..offset = offset
        ..portalTheaterToLeaderOffset = portalTheaterToLeaderOffset
        ..debugLabel = debugLabel;
    }
    context.pushLayer(layer!, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomLayerLink>('link', link));
    properties.add(DiagnosticsProperty('debugLabel', debugLabel));
  }
}

/// @nodoc
class CustomRenderFollowerLayer extends RenderProxyBox {
  /// @nodoc
  CustomRenderFollowerLayer({
    required CustomLayerLink link,
    // NOTE MODIFIED some arguments
    required PortalLink portalLink,
    required Size targetSize,
    required Anchor anchor,
    required String? debugLabel,
    RenderBox? child,
  })  : _anchor = anchor,
        _link = link,
        _portalLink = portalLink,
        _targetSize = targetSize,
        _debugLabel = debugLabel,
        super(child);

  // NOTE MODIFIED original Flutter code lets user pass it in as an argument,
  // but we just make it a constant zero.
  static const showWhenUnlinked = false;

  /// @nodoc
  Anchor get anchor => _anchor;
  Anchor _anchor;

  set anchor(Anchor value) {
    if (_anchor != value) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  /// @nodoc
  CustomLayerLink get link => _link;
  CustomLayerLink _link;

  set link(CustomLayerLink value) {
    if (_link == value) {
      return;
    }
    _link = value;
    markNeedsPaint();
  }

  /// @nodoc
  PortalLink get portalLink => _portalLink;
  PortalLink _portalLink;

  set portalLink(PortalLink value) {
    if (_portalLink == value) {
      return;
    }
    _portalLink = value;
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
  String? get debugLabel => _debugLabel;
  String? _debugLabel;
  set debugLabel(String? value) {
    if (_debugLabel == value) return;
    _debugLabel = value;
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
  CustomFollowerLayer? get layer => super.layer as CustomFollowerLayer?;

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
  /// the leader is only attached to the [CustomLayerLink] in [LeaderLayer.attach],
  /// which is called in the compositing phase which is after the paint phase.
  Offset _computeLinkedOffset(Offset leaderOffset) {
    assert(
      portalLink.theater != null,
      'The theater must be set in the OverlayLink when the '
      '_RenderPortalTheater is inserted as a child of the _PortalLinkScope. '
      'Therefore, it must not be null in any child PortalEntry.',
    );
    final theater = portalLink.theater!;

    // TODO new method!
    final theaterShift = link.leader!.portalTheaterToLeaderOffset;
    // // In order to compute the theater rect, we must first offset (shift) it by
    // // the position of the top-left corner of the target in the coordinate space
    // // of the theater since we are working with it relative to the target.
    // final theaterShift = -globalToLocal(
    //   leaderOffset,
    //   ancestor: theater,
    // );

    final theaterRect = theaterShift & theater.size;

    // if (true || debugLabel == 'CSTextMarkSpanSegmentSideWidget-toolbar') {
    //   final lines = <String>[];
    //   lines.add('START' + '=' * 50);
    //   lines.add(
    //       'hi computeLinkedOffset (self=$debugLabel, theater=${theater.debugName}) '
    //       'leaderOffset=$leaderOffset theaterShift=$theaterShift theaterSize=${theater.size} '
    //       'theater-to-FollowerLayer=${this.globalToLocal(Offset.zero, ancestor: theater)} '
    //       'FollowerLayer.globalToLocal=${this.globalToLocal(Offset.zero)} '
    //       'Portal(Theater).globalToLocal=${theater.globalToLocal(Offset.zero)} ');
    //   this.myGetTransformTo(
    //       theater, "$debugLabel theater-to-FollowerLayer", lines);
    //   this.myGetTransformTo(null, "$debugLabel FollowerLayer", lines);
    //   theater.myGetTransformTo(null, "$debugLabel Portal(Theater)", lines);
    //   lines.add('END' + '=' * 50);
    //
    //   print(lines.join('\n'));
    //   //   debugDumpTextToFile(lines.join('\n'), filePrefix: 'portal');
    // }

    return anchor.getFollowerOffset(
      // The size is set in performLayout of the RenderProxyBoxMixin.
      followerSize: size,
      targetSize: targetSize,
      portalRect: theaterRect,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // NOTE MODIFIED removed original [effectiveLinkedOffset] calculation, and replace with callback

    if (layer == null) {
      layer = CustomFollowerLayer(
        link: link,
        linkedOffsetCallback: _computeLinkedOffset,
        debugLabel: debugLabel,
      );
    } else {
      layer
        ?..link = link
        ..linkedOffsetCallback = _computeLinkedOffset
        ..debugLabel = debugLabel;
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
    properties.add(DiagnosticsProperty<PortalLink>('portalLink', portalLink));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
    properties.add(DiagnosticsProperty('anchor', anchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
    properties.add(DiagnosticsProperty('debugLabel', debugLabel));
  }
}

extension on RenderObject {
  Matrix4 myGetTransformTo(
      RenderObject? ancestor, String hiName, List<String> lines) {
    final bool ancestorSpecified = ancestor != null;
    assert(attached);
    if (ancestor == null) {
      final AbstractNode? rootNode = owner!.rootNode;
      if (rootNode is RenderObject) ancestor = rootNode;
    }
    final List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this;
        renderer != ancestor;
        renderer = renderer.parent! as RenderObject) {
      renderers.add(renderer);
      assert(
          renderer.parent != null); // Failed to find ancestor in parent chain.
    }
    // print('hi myGetTransformTo renderer.parent=${renderers.last.parent} ancestor=$ancestor');
    if (ancestorSpecified) renderers.add(ancestor!);
    lines.add('hi myGetTransformTo $hiName renderers=$renderers');
    final Matrix4 transform = Matrix4.identity();
    for (int index = renderers.length - 1; index > 0; index -= 1) {
      renderers[index].applyPaintTransform(renderers[index - 1], transform);
      lines.add(
          'hi myGetTransformTo $hiName inside-loop after index=$index renderers[index]=${renderers[index]} transform=$transform');
    }
    lines.add('hi myGetTransformTo $hiName ans=$transform');
    return transform;
  }
}
