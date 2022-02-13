import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'anchor.dart';
import 'custom_follower.dart';

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
  const Portal({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  _PortalState createState() => _PortalState();
}

class _PortalState extends State<Portal> {
  final _overlayLink = OverlayLink();

  @override
  Widget build(BuildContext context) {
    return _PortalLinkScope(
      overlayLink: _overlayLink,
      child: _PortalTheater(
        overlayLink: _overlayLink,
        child: widget.child,
      ),
    );
  }
}

class OverlayLink {
  _RenderPortalTheater? theater;

  BoxConstraints? get constraints => theater?.constraints;

  final Set<RenderBox> overlays = {};
}

class _PortalLinkScope extends InheritedWidget {
  const _PortalLinkScope({
    Key? key,
    required OverlayLink overlayLink,
    required Widget child,
  })  : _overlayLink = overlayLink,
        super(key: key, child: child);

  final OverlayLink _overlayLink;

  @override
  bool updateShouldNotify(_PortalLinkScope oldWidget) {
    return oldWidget._overlayLink != _overlayLink;
  }
}

class _PortalTheater extends SingleChildRenderObjectWidget {
  const _PortalTheater({
    Key? key,
    required OverlayLink overlayLink,
    required Widget child,
  })  : _overlayLink = overlayLink,
        super(key: key, child: child);

  final OverlayLink _overlayLink;

  @override
  _RenderPortalTheater createRenderObject(BuildContext context) {
    return _RenderPortalTheater(_overlayLink);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPortalTheater renderObject,
  ) {
    renderObject.overlayLink = _overlayLink;
  }
}

class _RenderPortalTheater extends RenderProxyBox {
  _RenderPortalTheater(this._overlayLink) {
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
    for (final overlay in overlayLink.overlays) {
      if (overlay.hitTest(result, position: position)) {
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

/// Widget that is passed to a [PortalTarget] as the follower that is overlaid
/// on top of other content in a [Portal].
///
/// This is just a regular [Widget] that is passed as
/// [PortalTarget.portalFollower]. The target takes care of making it a
/// follower → it is only a typedef.
typedef PortalFollower = Widget;

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
    required this.child,
  })  : assert(visible == false || portalFollower != null),
        super(key: key);

  // ignore: diagnostic_describe_all_properties, conflicts with closeDuration
  final bool visible;
  final Anchor anchor;
  final Duration? closeDuration;
  final PortalFollower? portalFollower;
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
      ..add(DiagnosticsProperty<Widget>('child', child));
  }
}

class _PortalTargetState extends State<PortalTarget> {
  final _link = LayerLink();
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
    final scope =
        context.dependOnInheritedWidgetOfExactType<_PortalLinkScope>();
    if (scope == null) {
      throw PortalNotFoundError._(widget);
    }

    if (widget.anchor is Filled) {
      return _PortalTargetTheater(
        portalFollower: _visible ? widget.portalFollower : null,
        anchor: widget.anchor,
        targetSize: Size.zero,
        overlayLink: scope._overlayLink,
        child: widget.child,
      );
    }

    return Stack(
      children: <Widget>[
        CompositedTransformTarget(
          link: _link,
          child: widget.child,
        ),
        if (_visible)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final targetSize = constraints.biggest;

                return _PortalTargetTheater(
                  overlayLink: scope._overlayLink,
                  anchor: widget.anchor,
                  targetSize: targetSize,
                  portalFollower: CustomCompositedTransformFollower(
                    link: _link,
                    overlayLink: scope._overlayLink,
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _PortalTargetTheater extends SingleChildRenderObjectWidget {
  const _PortalTargetTheater({
    Key? key,
    required this.portalFollower,
    required this.overlayLink,
    required this.anchor,
    required this.targetSize,
    required Widget child,
  }) : super(key: key, child: child);

  final Widget? portalFollower;
  final Anchor anchor;
  final OverlayLink overlayLink;
  final Size targetSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPortalTarget(
      overlayLink,
      anchor: anchor,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPortalTarget renderObject,
  ) {
    renderObject
      ..overlayLink = overlayLink
      ..anchor = anchor
      ..targetSize = targetSize;
  }

  @override
  SingleChildRenderObjectElement createElement() => _PortalTargetElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Anchor>('anchor', anchor));
    properties.add(DiagnosticsProperty<Size>('targetSize', targetSize));
    properties.add(
      DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink),
    );
  }
}

class _RenderPortalTarget extends RenderProxyBox {
  _RenderPortalTarget(
    this._overlayLink, {
    required Anchor anchor,
    required Size targetSize,
  })  : assert(_overlayLink.theater != null),
        _anchor = anchor,
        _targetSize = targetSize;

  bool _needsAddEntryInTheater = false;

  OverlayLink _overlayLink;

  OverlayLink get overlayLink => _overlayLink;

  set overlayLink(OverlayLink value) {
    assert(value.theater != null);
    if (_overlayLink != value) {
      _overlayLink = value;
      markNeedsLayout();
    }
  }

  Anchor _anchor;

  Anchor get anchor => _anchor;

  set anchor(Anchor value) {
    if (value != _anchor) {
      _anchor = value;
      markNeedsLayout();
    }
  }

  Size _targetSize;

  Size get targetSize => _targetSize;

  set targetSize(Size value) {
    if (value != _targetSize) {
      _targetSize = value;
      markNeedsLayout();
    }
  }

  RenderBox? _branch;

  RenderBox? get branch => _branch;

  set branch(RenderBox? value) {
    if (_branch != null) {
      _overlayLink.overlays.remove(branch);
      _overlayLink.theater!.markNeedsPaint();
      dropChild(_branch!);
    }
    _branch = value;
    if (_branch != null) {
      markNeedsAddEntryInTheater();
      adoptChild(_branch!);
    }
  }

  void markNeedsAddEntryInTheater() {
    _needsAddEntryInTheater = true;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_branch != null) {
      markNeedsAddEntryInTheater();
      _branch!.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    if (_branch != null) {
      _overlayLink.overlays.remove(branch);
      _overlayLink.theater!.markNeedsPaint();
      _branch!.detach();
    }
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    overlayLink.theater!.markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (branch != null) {
      final constraints = anchor.getFollowerConstraints(
        portalConstraints: overlayLink.constraints!,
        targetSize: targetSize,
      );
      branch!.layout(constraints);
      if (_needsAddEntryInTheater) {
        _needsAddEntryInTheater = false;
        _overlayLink.overlays.add(branch!);
        _overlayLink.theater!.markNeedsPaint();
      }
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == branch) {
      // ignore all transformations applied between Portal and PortalTarget
      transform.setFrom(overlayLink.theater!.getTransformTo(null));
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    if (branch != null) {
      redepthChild(branch!);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    if (branch != null) {
      visitor(branch!);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<OverlayLink>('overlayLink', overlayLink))
      ..add(DiagnosticsProperty<Anchor>('anchor', anchor))
      ..add(DiagnosticsProperty<Size>('targetSize', targetSize))
      ..add(DiagnosticsProperty<RenderBox>('branch', branch));
  }
}

class _PortalTargetElement extends SingleChildRenderObjectElement {
  _PortalTargetElement(_PortalTargetTheater widget) : super(widget);

  @override
  _PortalTargetTheater get widget => super.widget as _PortalTargetTheater;

  @override
  _RenderPortalTarget get renderObject =>
      super.renderObject as _RenderPortalTarget;

  Element? _branch;

  final _branchSlot = 42;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _branch = updateChild(_branch, widget.portalFollower, _branchSlot);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _branch = updateChild(_branch, widget.portalFollower, _branchSlot);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // branch first so that it is unmounted before the main tree
    if (_branch != null) {
      visitor(_branch!);
    }
    super.visitChildren(visitor);
  }

  @override
  void forgetChild(Element child) {
    if (child == _branch) {
      _branch = null;
    } else {
      super.forgetChild(child);
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    if (slot == _branchSlot) {
      renderObject.branch = child as RenderBox;
    } else {
      super.insertRenderObjectChild(child, slot);
    }
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    dynamic oldSlot,
    dynamic newSlot,
  ) {
    if (newSlot != _branchSlot) {
      super.moveRenderObjectChild(child, oldSlot, newSlot);
    }
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    if (child == renderObject.branch) {
      renderObject.branch = null;
    } else {
      super.removeRenderObjectChild(child, slot);
    }
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
