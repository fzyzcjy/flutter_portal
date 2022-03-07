// ignore_for_file: diagnostic_describe_all_properties

import 'package:flutter/material.dart';
import 'portal.dart';
import 'portal_theater.dart';

class OverlayLink {
  RenderPortalTheater? theater;

  BoxConstraints? get constraints => theater?.constraints;

  final Set<RenderBox> overlays = {};
}

class PortalLinkScope extends InheritedWidget {
  const PortalLinkScope({
    Key? key,
    required this.overlayLink,
    required this.portalIdentifier,
    required Widget child,
  }) : super(key: key, child: child);

  final OverlayLink overlayLink;
  final PortalIdentifier? portalIdentifier;

  @override
  bool updateShouldNotify(PortalLinkScope oldWidget) {
    return oldWidget.overlayLink != overlayLink ||
        oldWidget.portalIdentifier != portalIdentifier;
  }
}
