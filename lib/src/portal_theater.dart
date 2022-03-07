import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'portal_link.dart';

class PortalTheater extends SingleChildRenderObjectWidget {
  const PortalTheater({
    Key? key,
    required OverlayLink overlayLink,
    required Widget child,
  })  : _overlayLink = overlayLink,
        super(key: key, child: child);

  final OverlayLink _overlayLink;

  @override
  RenderPortalTheater createRenderObject(BuildContext context) {
    return RenderPortalTheater(_overlayLink);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPortalTheater renderObject,
  ) {
    renderObject.overlayLink = _overlayLink;
  }
}

class RenderPortalTheater extends RenderProxyBox {
  RenderPortalTheater(this._overlayLink) {
    _overlayLink.theater = this;
  }

  OverlayLink _overlayLink;

  OverlayLink get overlayLink => _overlayLink;

  set overlayLink(OverlayLink value) {
    if (_overlayLink != value) {
      assert(
        value.theater == null,
        'overlayLink already assigned to another portal',
      );
      _overlayLink.theater = null;
      _overlayLink = value;
      value.theater = this;
    }
  }

  @override
  void markNeedsLayout() {
    for (final overlay in overlayLink.overlays) {
      overlay.markNeedsLayout();
    }
    super.markNeedsLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    for (var i = overlayLink.overlays.length - 1; i >= 0; i--) {
      final overlay = overlayLink.overlays.elementAt(i);
      context.paintChild(overlay, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final globalPosition = localToGlobal(position); // #42
    for (final overlay in overlayLink.overlays) {
      if (overlay.hitTest(result, position: globalPosition /* #42 */)) {
        return true;
      }
    }

    return super.hitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink),
    );
  }
}
