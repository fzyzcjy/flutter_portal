// NOTE adapted from Flutter beta 2.11.0-0.1.pre (notice beta, not stable)
// Please place a `NOTE MODIFIED` marker whenever you change the Flutter code

// ignore_for_file: unnecessary_null_comparison, diagnostic_describe_all_properties

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../anchor.dart';
import '../portal.dart';
import 'rendering_layer.dart';
import 'rendering_proxy_box.dart';

/// @nodoc
class CustomCompositedTransformTarget extends SingleChildRenderObjectWidget {
  /// @nodoc
  const CustomCompositedTransformTarget({
    Key? key,
    required this.link,
    Widget? child,
  })  : assert(link != null),
        super(key: key, child: child);

  /// @nodoc
  final CustomLayerLink link;

  @override
  CustomRenderLeaderLayer createRenderObject(BuildContext context) {
    return CustomRenderLeaderLayer(
      link: link,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, CustomRenderLeaderLayer renderObject) {
    renderObject.link = link;
  }
}

/// @nodoc
class CustomCompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// @nodoc
  const CustomCompositedTransformFollower({
    Key? key,
    required this.link,
    // NOTE MODIFIED some arguments
    required this.overlayLink,
    required this.targetSize,
    required this.anchor,
    Widget? child,
  }) : super(key: key, child: child);

  /// @nodoc
  final Anchor anchor;

  /// @nodoc
  final CustomLayerLink link;

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
  void updateRenderObject( BuildContext context, CustomRenderFollowerLayer renderObject ) {
    renderObject
      ..link = link
      ..overlayLink = overlayLink
      ..targetSize = targetSize
      ..anchor = anchor;
  }
}
