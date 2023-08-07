import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // ignore: unnecessary_import

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
    this.labels = const [PortalLabel.main],
    required this.child,
  }) : super(key: key);

  final String? debugName;
  final List<PortalLabel<dynamic>> labels;
  final Widget child;

  @override
  _PortalState createState() => _PortalState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugName', debugName));
    properties.add(DiagnosticsProperty('labels', labels));
  }
}

class _PortalState extends State<Portal> {
  final _portalLink = PortalLink();

  @override
  Widget build(BuildContext context) {
    return PortalLinkScope(
      debugName: widget.debugName,
      portalLabels: widget.labels,
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

// implementation references [ValueKey]
@immutable
class PortalLabel<T> {
  /// Creates a portal label that delegates its [operator==] to the given value.
  const PortalLabel(this.value);

  /// The value to which this portal label delegates its [operator==]
  final T value;

  static const main = _PortalMainLabel();

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is PortalLabel<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    final valueString = T == String ? "<'$value'>" : '<$value>';
    // ignore: no_runtimeType_toString
    return '$runtimeType($T $valueString)';
  }
}

class _PortalMainLabel extends PortalLabel<void> {
  const _PortalMainLabel() : super(null);

  @override
  String toString() => 'PortalLabel.main';
}
