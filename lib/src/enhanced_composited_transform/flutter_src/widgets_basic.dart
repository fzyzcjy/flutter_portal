// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, diagnostic_describe_all_properties

import 'package:flutter/material.dart';
import '../anchor.dart';
import 'rendering_layer.dart';
import 'rendering_proxy_box.dart';

/// @nodoc
class EnhancedCompositedTransformTarget extends SingleChildRenderObjectWidget {
  /// @nodoc
  const EnhancedCompositedTransformTarget({
    Key? key,
    required this.link,
    // NOTE MODIFIED some arguments
    required this.theaterGetter,
    this.debugName,
    Widget? child,
  })  : assert(link != null),
        super(key: key, child: child);

  /// @nodoc
  final EnhancedLayerLink link;

  /// @nodoc
  final TheaterGetter theaterGetter;

  // NOTE MODIFIED add
  final String? debugName;

  @override
  EnhancedRenderLeaderLayer createRenderObject(BuildContext context) {
    return EnhancedRenderLeaderLayer(
      link: link,
      theaterGetter: theaterGetter,
      debugName: debugName,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, EnhancedRenderLeaderLayer renderObject) {
    renderObject
      ..link = link
      ..theaterGetter = theaterGetter
      ..debugName = debugName;
  }
}

/// @nodoc
class EnhancedCompositedTransformFollower
    extends SingleChildRenderObjectWidget {
  /// @nodoc
  const EnhancedCompositedTransformFollower({
    Key? key,
    required this.link,
    this.showWhenUnlinked = true,
    // NOTE MODIFIED some arguments
    required this.targetSize,
    required this.anchor,
    this.debugName,
    Widget? child,
  }) : super(key: key, child: child);

  /// @nodoc
  final EnhancedCompositedTransformAnchor anchor;

  /// @nodoc
  final EnhancedLayerLink link;

  final bool showWhenUnlinked;

  /// @nodoc
  final Size targetSize;

  // NOTE MODIFIED add
  final String? debugName;

  @override
  EnhancedRenderFollowerLayer createRenderObject(BuildContext context) {
    return EnhancedRenderFollowerLayer(
      anchor: anchor,
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      targetSize: targetSize,
      debugName: debugName,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, EnhancedRenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..targetSize = targetSize
      ..anchor = anchor
      ..debugName = debugName;
  }
}
