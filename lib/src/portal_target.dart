import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'anchor.dart';
import 'enhanced_composited_transform/flutter_src/rendering_layer.dart';
import 'enhanced_composited_transform/flutter_src/widgets_basic.dart';
import 'portal.dart';
import 'portal_link.dart';
import 'portal_target_theater.dart';

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
    this.portalCandidateLabels = const [PortalLabel.main],
    this.debugName,
    required this.child,
  })  : assert(visible == false || portalFollower != null),
        super(key: key);

  // ignore: diagnostic_describe_all_properties, conflicts with closeDuration
  final bool visible;
  final Anchor anchor;
  final Duration? closeDuration;
  final PortalFollower? portalFollower;
  final List<PortalLabel<dynamic>> portalCandidateLabels;
  final String? debugName;
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
      ..add(DiagnosticsProperty<List<PortalLabel>>(
          'portalCandidateLabels', portalCandidateLabels))
      ..add(DiagnosticsProperty('debugName', debugName))
      ..add(DiagnosticsProperty<Widget>('child', child));
  }

  /// See which [Portal] will indeed be used given the configuration
  /// Visible only for debugging purpose.
  static String? debugResolvePortal(
    BuildContext context,
    List<PortalLabel<dynamic>> portalCandidateLabels,
  ) {
    final scope = _dependOnScope(context, portalCandidateLabels);
    if (scope == null) {
      return null;
    }
    return '(debugName: ${scope.debugName}, portalLabel: ${scope.portalLabels})';
  }

  static PortalLinkScope? _dependOnScope(
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

class _PortalTargetState extends State<PortalTarget> {
  final _link = EnhancedLayerLink();

  @override
  Widget build(BuildContext context) {
    return _PortalTargetVisibilityBuilder(
      visible: widget.visible,
      closeDuration: widget.closeDuration,
      builder: (context, currentVisible) {
        final scope =
            PortalTarget._dependOnScope(context, widget.portalCandidateLabels);
        if (scope == null) {
          throw PortalNotFoundError._(widget);
        }

        if (widget.anchor is Filled) {
          return _buildModeFilled(currentVisible, scope);
        }

        return _buildModeNormal(context, currentVisible, scope);
      },
    );
  }

  Widget _buildModeNormal(
      BuildContext context, bool currentVisible, PortalLinkScope scope) {
    _sanityCheckNestedPortalTarget(context, scope);

    return Stack(
      children: <Widget>[
        EnhancedCompositedTransformTarget(
          link: _link,
          theaterInfo: scope.theaterInfo,
          debugName: widget.debugName,
          child: widget.child,
        ),
        if (currentVisible)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final targetSize = constraints.biggest;

                return PortalTargetTheater(
                  portalLink: scope.portalLink,
                  anchor: widget.anchor,
                  targetSize: targetSize,
                  portalFollower: EnhancedCompositedTransformFollower(
                    link: _link,
                    theaterInfo: scope.theaterInfo,
                    anchor: widget.anchor,
                    targetSize: targetSize,
                    debugName: widget.debugName,
                    child: widget.portalFollower == null
                        ? null
                        : _PortalTargetTheaterFollowerParent(
                            usedScope: scope,
                            debugSelfWidget: widget,
                            child: widget.portalFollower!,
                          ),
                  ),
                  child: const SizedBox.shrink(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildModeFilled(bool currentVisible, PortalLinkScope scope) {
    return PortalTargetTheater(
      portalFollower: currentVisible ? widget.portalFollower : null,
      anchor: widget.anchor,
      targetSize: Size.zero,
      portalLink: scope.portalLink,
      child: widget.child,
    );
  }

  void _sanityCheckNestedPortalTarget(
      BuildContext context, PortalLinkScope scope) {
    final portalLinkScopeAncestors = context
        .getElementsForInheritedWidgetsOfExactType<PortalLinkScope>()
        .map((element) =>
            context.dependOnInheritedElement(element) as PortalLinkScope)
        .toList();

    for (final followerParentElement
        in context.getElementsForInheritedWidgetsOfExactType<
            _PortalTargetTheaterFollowerParent>()) {
      final followerParent =
          context.dependOnInheritedElement(followerParentElement)
              as _PortalTargetTheaterFollowerParent;
      final parentScope = followerParent.usedScope;

      // #60
      final underPortalForCurrent = followerParentElement
              .getSpecificElementForInheritedWidgetsOfExactType<
                  PortalLinkScope>(scope.linkEquals) !=
          null;
      if (!underPortalForCurrent) {
        break;
      }

      final followerParentUsedScopeIndex =
          portalLinkScopeAncestors.indexWhere(parentScope.linkEquals);
      final selfUsedScopeIndex =
          portalLinkScopeAncestors.indexWhere(scope.linkEquals);

      final info = SanityCheckNestedPortalInfo._(
        selfDebugLabel: widget.debugName,
        parentDebugLabel: followerParent.debugSelfWidget.debugName,
        selfScope: scope,
        parentScope: parentScope,
        portalLinkScopeAncestors: portalLinkScopeAncestors,
      );

      if (followerParentUsedScopeIndex == -1) {
        throw Exception('Cannot find followerParentUsedScopeIndex info=$info');
      }
      if (selfUsedScopeIndex == -1) {
        throw Exception('Cannot find selfUsedScopeIndex info=$info');
      }

      if (selfUsedScopeIndex < followerParentUsedScopeIndex) {
        // see #57
        throw SanityCheckNestedPortalError._(info);
      }
    }
  }
}

class _PortalTargetVisibilityBuilder extends StatefulWidget {
  const _PortalTargetVisibilityBuilder({
    Key? key,
    required this.visible,
    required this.closeDuration,
    required this.builder,
  }) : super(key: key);

  final bool visible;
  final Duration? closeDuration;
  final Widget Function(BuildContext, bool currentVisible) builder;

  @override
  _PortalTargetVisibilityBuilderState createState() =>
      _PortalTargetVisibilityBuilderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('visible', visible));
    properties
        .add(DiagnosticsProperty<Duration?>('closeDuration', closeDuration));
    properties.add(DiagnosticsProperty('builder', builder));
  }
}

class _PortalTargetVisibilityBuilderState
    extends State<_PortalTargetVisibilityBuilder> {
  late bool _visible = widget.visible;
  Timer? _timer;

  @override
  void didUpdateWidget(_PortalTargetVisibilityBuilder oldWidget) {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _visible);
  }
}

class _PortalTargetTheaterFollowerParent extends InheritedWidget {
  const _PortalTargetTheaterFollowerParent({
    Key? key,
    required this.debugSelfWidget,
    required this.usedScope,
    required Widget child,
  }) : super(key: key, child: child);

  final PortalTarget debugSelfWidget;
  final PortalLinkScope usedScope;

  @override
  bool updateShouldNotify(_PortalTargetTheaterFollowerParent old) {
    return old.usedScope != usedScope;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('builder', debugSelfWidget));
    properties.add(DiagnosticsProperty('usedScope', usedScope));
  }
}

/// The error that is thrown when a [PortalTarget] fails to find a [Portal].
class PortalNotFoundError extends Error {
  PortalNotFoundError._(this._portalTarget);

  final PortalTarget _portalTarget;

  @override
  String toString() {
    return '''
Error: Could not find a Portal above this PortalTarget(debugName: ${_portalTarget.debugName}, portalCandidateLabels=${_portalTarget.portalCandidateLabels}).
''';
  }
}

class SanityCheckNestedPortalError extends Error {
  SanityCheckNestedPortalError._(this.info);

  final SanityCheckNestedPortalInfo info;

  @override
  String toString() => 'SanityCheckNestedPortalError: '
      'When a `PortalTarget` is in the `PortalTarget.portalFollower` subtree of another `PortalTarget`, '
      'the `Portal` bound by the first `PortalTarget` should be *lower* than the `Portal` bound by the second. '
      'However, currently the reverse is true. '
      'info: $info';
}

@immutable
class SanityCheckNestedPortalInfo {
  const SanityCheckNestedPortalInfo._({
    required this.selfDebugLabel,
    required this.parentDebugLabel,
    required this.selfScope,
    required this.parentScope,
    required this.portalLinkScopeAncestors,
  });

  final String? selfDebugLabel;
  final String? parentDebugLabel;
  final PortalLinkScope selfScope;
  final PortalLinkScope parentScope;
  final List<PortalLinkScope> portalLinkScopeAncestors;

  @override
  String toString() => 'SanityCheckNestedPortalInfo{'
      'selfDebugLabel: $selfDebugLabel, '
      'parentDebugLabel: $parentDebugLabel, '
      'selfScope: ${_scopeToString(selfScope)}, '
      'parentScope: ${_scopeToString(parentScope)}, '
      'portalLinkScopeAncestors: ${portalLinkScopeAncestors.map(_scopeToString).toList()}'
      '}';

  String _scopeToString(PortalLinkScope scope) =>
      '$scope(hash=${shortHash(scope)})';
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
