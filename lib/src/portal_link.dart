// ignore_for_file: diagnostic_describe_all_properties

import 'package:flutter/material.dart';
import 'portal.dart';
import 'portal_theater.dart';

class PortalLink {
  RenderPortalTheater? theater;

  BoxConstraints? get constraints => theater?.constraints;

  final overlays = <RenderBox>{};
}

class PortalLinkScope extends InheritedWidget {
  const PortalLinkScope({
    Key? key,
    required this.portalLink,
    required this.portalIdentifier,
    required Widget child,
  }) : super(key: key, child: child);

  final PortalLink portalLink;
  final PortalIdentifier? portalIdentifier;

  @override
  bool updateShouldNotify(PortalLinkScope oldWidget) {
    return oldWidget.portalLink != portalLink ||
        oldWidget.portalIdentifier != portalIdentifier;
  }
}
