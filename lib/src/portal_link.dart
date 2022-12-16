import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../flutter_portal.dart';
import 'portal_theater.dart';

class PortalLink {
  RenderPortalTheater? theater;

  BoxConstraints? get constraints => theater?.constraints;

  final overlays = <PortalLinkOverlay>{};

  @override
  String toString() => 'PortalLink#${shortHash(this)}';
}

@immutable
class PortalLinkOverlay {
  const PortalLinkOverlay(this.overlay, this.anchor);

  final RenderBox overlay;
  final Anchor anchor;

  // ONLY consider overlay, does NOT consider anchor
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortalLinkOverlay &&
          runtimeType == other.runtimeType &&
          overlay == other.overlay;

  @override
  int get hashCode => overlay.hashCode;
}

class PortalLinkScope extends InheritedWidget {
  const PortalLinkScope({
    Key? key,
    required this.debugName,
    required this.portalLink,
    required this.portalLabels,
    required Widget child,
  }) : super(key: key, child: child);

  final String? debugName;
  final PortalLink portalLink;
  final List<PortalLabel<dynamic>> portalLabels;

  @override
  bool updateShouldNotify(PortalLinkScope oldWidget) {
    return oldWidget.portalLink != portalLink ||
        !listEquals(oldWidget.portalLabels, portalLabels);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugName', debugName));
    properties.add(DiagnosticsProperty('portalLink', portalLink));
    properties.add(DiagnosticsProperty('portalLabel', portalLabels));
  }

  bool linkEquals(PortalLinkScope other) => portalLink == other.portalLink;

  static PortalLinkScope? of(
    BuildContext context,
    List<PortalLabel<dynamic>> portalCandidateLabels,
  ) {
    for (final portalLabel in portalCandidateLabels) {
      final scope =
          context.dependOnSpecificInheritedWidgetOfExactType<PortalLinkScope>(
              (scope) => scope.portalLabels.contains(portalLabel));
      if (scope != null) {
        return scope;
      }
    }
    return null;
  }
}

extension BuildContextPortalLinkScopeExt on BuildContext {
  /// https://stackoverflow.com/questions/71200969
  Iterable<InheritedElement> getElementsForInheritedWidgetsOfExactType<
      T extends InheritedWidget>() sync* {
    final element = getElementForInheritedWidgetOfExactType<T>();
    if (element != null) {
      yield element;

      Element? parent;
      element.visitAncestorElements((element) {
        parent = element;
        return false;
      });

      if (parent != null) {
        yield* parent!.getElementsForInheritedWidgetsOfExactType<T>();
      }
    }
  }

  InheritedElement? getSpecificElementForInheritedWidgetsOfExactType<
          T extends InheritedWidget>(bool Function(T) test) =>
      getElementsForInheritedWidgetsOfExactType<T>()
          .where((element) => test(element.widget as T))
          .firstOrNull;

  /// https://stackoverflow.com/questions/71200969
  T? dependOnSpecificInheritedWidgetOfExactType<T extends InheritedWidget>(
      bool Function(T) test) {
    final element = getSpecificElementForInheritedWidgetsOfExactType<T>(test);
    if (element == null) {
      return null;
    }
    return dependOnInheritedElement(element) as T;
  }
}
