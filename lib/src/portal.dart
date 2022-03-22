import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'portal_link.dart';
import 'portal_target.dart';
import 'portal_theater.dart';

/// The widget where a [PortalTarget] and its [PortalFollower] are rendered.
///
/// [Portal] can be considered as a reimplementation of [Overlay] to allow
/// adding an [OverlayEntry] (now named [PortalTarget]) declaratively.
///
/// The [Portal] widget is used in coordination with the [PortalTarget] widget
/// to show some content _above_ other content.
/// This is similar to [Stack] in principle, with the difference that a
/// [PortalTarget] does not have to be a direct child of [Portal] and can
/// instead be placed anywhere in the widget tree.
///
/// In most situations, [Portal] can be placed directly above [MaterialApp]:
///
/// ```dart
/// Portal(
///   child: MaterialApp(
///   ),
/// );
/// ```
///
/// This allows an overlay to render above _everything_ including all routes.
/// That can be useful to show a snackbar between pages.
///
/// You can optionally add a [Portal] inside your page:
///
/// ```dart
/// Portal(
///   child: Scaffold(
///   ),
/// )
/// ```
///
/// This way, your modals/snackbars will stop being visible when a new route
/// is pushed.
class Portal extends StatefulWidget {
  const Portal({
    Key? key,
    this.debugName,
    this.identifier = const PortalMainIdentifier(),
    required this.child,
  }) : super(key: key);

  final String? debugName;
  final PortalIdentifier identifier;
  final Widget child;

  @override
  _PortalState createState() => _PortalState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugName', debugName));
    properties
        .add(DiagnosticsProperty<PortalIdentifier>('identifier', identifier));
  }
}

class _PortalState extends State<Portal> {
  final _portalLink = PortalLink();

  @override
  Widget build(BuildContext context) {
    return PortalLinkScope(
      debugName: widget.debugName,
      portalIdentifier: widget.identifier,
      portalLink: _portalLink,
      child: PortalTheater(
        debugName: widget.debugName,
        portalLink: _portalLink,
        child: widget.child,
      ),
    );
  }
}

/// Widget that is passed to a [PortalTarget] as the follower that is overlaid
/// on top of other content in a [Portal].
///
/// This is just a regular [Widget] that is passed as
/// [PortalTarget.portalFollower]. The target takes care of making it a
/// follower → it is only a typedef.
typedef PortalFollower = Widget;

typedef AncestorPortalSelector = bool Function(
    PortalIdentifier portalIdentifier);

bool defaultAncestorPortalSelector(PortalIdentifier portalIdentifier) =>
    portalIdentifier == const PortalMainIdentifier();

// implementation references [ValueKey]
@immutable
class PortalIdentifier<T> {
  /// Creates a portal identifier that delegates its [operator==] to the given value.
  const PortalIdentifier(this.value);

  /// The value to which this portal identifier delegates its [operator==]
  final T value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PortalIdentifier<T> && other.value == value;
  }

  @override
  int get hashCode => hashValues(runtimeType, value);

  @override
  String toString() {
    final valueString = T == String ? "<'$value'>" : '<$value>';
    return '[$T $valueString]';
  }
}

class PortalMainIdentifier extends PortalIdentifier<void> {
  const PortalMainIdentifier() : super(null);
}
