import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'anchor.dart';
import 'flutter_src/rendering_layer.dart';
import 'flutter_src/widgets_basic.dart';
import 'portal.dart';
import 'portal_link.dart';
import 'portal_target_theater.dart';

// todo(creativecreatorormaybenot): update target docs.

/// A widget that renders its follower in a different location of the widget
/// tree.
///
/// Its [child] is rendered in the tree as you would expect, but its
/// [portalFollower] is rendered through the ancestor [Portal] in a different
/// location of the widget tree.
///
/// In short, you can use [PortalTarget] to show dialogs, tooltips, contextual
/// menus, etc.
/// You can then control the visibility of these overlays with a simple
/// `setState`.
///
/// The benefits of using [PortalTarget]/[PortalFollower] over
/// [Overlay]/[OverlayEntry] are multiple:
/// - [PortalTarget] is easier to manipulate
/// - It allows aligning your menus/tooltips next to a button easily
/// - It combines nicely with state-management solutions and the
///   "state-restoration" framework. For example, combined with
///   [RestorableProperty] when the application is killed then re-opened,
///   modals/menus would be restored.
///
/// For [PortalTarget] to work, make sure to insert [Portal] higher in the
/// widget tree.
///
/// ## Contextual menu example
///
/// In this example, we will see how we can use [PortalTarget] to show a menu
/// after clicking on a [ElevatedButton].
///
/// First, we need to create a [StatefulWidget] that renders our
/// [ElevatedButton]:
///
/// ```dart
/// class MenuExample extends StatefulWidget {
///   @override
///   _MenuExampleState createState() => _MenuExampleState();
/// }
///
/// class _MenuExampleState extends State<MenuExample> {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Center(
///         child: ElevatedButton(
///           onPressed: () {},
///           child: Text('show menu'),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// Then, we need to insert our [PortalTarget] in the widget tree.
///
/// We want our contextual menu to render right next to our [ElevatedButton].
/// As such, our [PortalTarget] should be the parent of [ElevatedButton] like
/// so:
///
/// ```dart
/// Center(
///   child: PortalTarget(
///     visible: // <todo>
///     portalFollower: // <todo>
///     child: ElevatedButton(
///       ...
///     ),
///   ),
/// )
/// ```
///
/// We can pass our menu as the `portalFollower` to [PortalTarget]:
///
///
/// ```dart
/// PortalTarget(
///   visible: true,
///   portalFollower: Material(
///     elevation: 8,
///     child: IntrinsicWidth(
///       child: Column(
///         mainAxisSize: MainAxisSize.min,
///         children: [
///           ListTile(title: Text('option 1')),
///           ListTile(title: Text('option 2')),
///         ],
///       ),
///     ),
///   ),
///   child: ElevatedButton(...),
/// )
/// ```
///
/// At this stage, you may notice two things:
///
/// - our menu is full-screen
/// - our menu is always visible (because `visible` is _true_)
///
/// Let's fix the full-screen issue first and change our code so that our
/// menu renders on the _right_ of our [ElevatedButton].
///
/// To align our menu around our button, we can specify the `anchor`
/// parameter:
///
/// ```dart
/// PortalEntry(
///   visible: true,
///   anchor: const Aligned(
///     follower: Alignment.topLeft,
///     target: Alignment.topRight,
///   ),
///   portalFollower: Material(...),
///   child: ElevatedButton(...),
/// )
/// ```
///
/// What this code means is, this will align the top-left of our menu with the
/// top-right or the [ElevatedButton].
/// With this, our menu is no longer full-screen and is now located to the right
/// of our button.
///
/// Finally, we can update our code such that the menu show only when clicking
/// on the button.
///
/// To do that, we need to declare a new boolean inside our [StatefulWidget],
/// that says whether the menu is open or not:
///
/// ```dart
/// class _MenuExampleState extends State<MenuExample> {
///   bool isMenuOpen = false;
///   ...
/// }
/// ```
///
/// We then pass this `isMenuOpen` variable to our [PortalEntry]:
///
/// ```dart
/// PortalTarget(
///   visible: isMenuOpen,
///   ...
/// )
/// ```
///
/// Then, inside the `onPressed` callback of our [ElevatedButton], we can
/// update this `isMenuOpen` variable:
///
/// ```dart
/// ElevatedButton(
///   onPressed: () {
///     setState(() {
///       isMenuOpen = true;
///     });
///   },
///   child: Text('show menu'),
/// ),
/// ```
///
///
/// One final step is to close the menu when the user clicks randomly outside
/// of the menu.
///
/// This can be implemented with a second [PortalTarget] combined with [GestureDetector]
/// like so:
///
///
/// ```dart
/// Center(
///   child: PortalTarget(
///     visible: isMenuOpen,
///     portalFollower: GestureDetector(
///       behavior: HitTestBehavior.opaque,
///       onTap: () {
///         setState(() {
///           isMenuOpen = false;
///         });
///       },
///     ),
///     child: PortalTarget(
///       // our previous PortalTarget
///       portalFollower: Material(...)
///       child: ElevatedButton(...),
///     ),
///   ),
/// )
/// ```
class PortalTarget extends StatefulWidget {
  const PortalTarget({
    Key? key,
    this.visible = true,
    this.anchor = const Filled(),
    this.closeDuration,
    this.portalFollower,
    this.ancestorPortalSelector,
    required this.child,
  })  : assert(visible == false || portalFollower != null),
        super(key: key);

  // ignore: diagnostic_describe_all_properties, conflicts with closeDuration
  final bool visible;
  final Anchor anchor;
  final Duration? closeDuration;
  final PortalFollower? portalFollower;
  final AncestorPortalSelector? ancestorPortalSelector;
  final Widget child;

  @override
  _PortalTargetState createState() => _PortalTargetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Anchor>('anchor', anchor))
      ..add(DiagnosticsProperty<Duration>('closeDuration', closeDuration))
      ..add(DiagnosticsProperty<Widget>('portalFollower', portalFollower))
      ..add(ObjectFlagProperty<AncestorPortalSelector?>.has(
          'ancestorPortalSelector', ancestorPortalSelector))
      ..add(DiagnosticsProperty<Widget>('child', child));
  }
}

class _PortalTargetState extends State<PortalTarget> {
  final _link = CustomLayerLink();
  late bool _visible = widget.visible;
  Timer? _timer;

  @override
  void didUpdateWidget(PortalTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible) {
      if (!oldWidget.visible && _visible) {
        // rebuild when the portal is in progress of being hidden
      } else if (oldWidget.visible && widget.closeDuration != null) {
        _timer?.cancel();
        _timer = Timer(widget.closeDuration!, () {
          setState(() => _visible = false);
        });
      } else {
        _visible = false;
      }
    } else {
      _timer?.cancel();
      _timer = null;
      _visible = widget.visible;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _dependOnPortalLinkScope();
    if (scope == null) {
      throw PortalNotFoundError._(widget);
    }

    if (!widget.anchor.enablePortalFollowerLinking) {
      return PortalTargetTheater(
        portalFollower: _visible ? widget.portalFollower : null,
        anchor: widget.anchor,
        targetSize: Size.zero,
        portalLink: scope.portalLink,
        child: widget.child,
      );
    }

    return Stack(
      children: <Widget>[
        CustomCompositedTransformTarget(
          link: _link,
          child: widget.child,
        ),
        if (_visible)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final targetSize = constraints.biggest;

                return PortalTargetTheater(
                  portalLink: scope.portalLink,
                  anchor: widget.anchor,
                  targetSize: targetSize,
                  portalFollower: CustomCompositedTransformFollower(
                    link: _link,
                    portalLink: scope.portalLink,
                    anchor: widget.anchor,
                    targetSize: targetSize,
                    child: widget.portalFollower,
                  ),
                  child: const SizedBox.shrink(),
                );
              },
            ),
          ),
      ],
    );
  }

  PortalLinkScope? _dependOnPortalLinkScope() {
    // 1. User-provided selector
    final ancestorPortalSelector = widget.ancestorPortalSelector;
    if (ancestorPortalSelector != null) {
      return context
          .dependOnSpecificInheritedWidgetOfExactType<PortalLinkScope>(
              (scope) => ancestorPortalSelector(scope.portalIdentifier));
    }

    // 2. "main" scope
    final mainScope =
        context.dependOnSpecificInheritedWidgetOfExactType<PortalLinkScope>(
            (scope) => scope.portalIdentifier == const PortalMainIdentifier());
    if (mainScope != null) {
      return mainScope;
    }

    // 3. nearest scope
    return context.dependOnSpecificInheritedWidgetOfExactType<PortalLinkScope>(
        (scope) => true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// The error that is thrown when a [PortalTarget] fails to find a [Portal].
class PortalNotFoundError<T extends Portal> extends Error {
  PortalNotFoundError._(this._portalTarget);

  final PortalTarget _portalTarget;

  @override
  String toString() {
    return '''
Error: Could not find a $T above this $_portalTarget.
''';
  }
}

extension on BuildContext {
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

  /// https://stackoverflow.com/questions/71200969
  T? dependOnSpecificInheritedWidgetOfExactType<T extends InheritedWidget>(
      bool Function(T) test) {
    final element = getElementsForInheritedWidgetsOfExactType<T>()
        .where((element) => test(element.widget as T))
        .firstOrNull;
    if (element == null) {
      return null;
    }
    return dependOnInheritedElement(element) as T;
  }
}
