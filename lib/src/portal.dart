import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'custom_follower.dart';

class Portal extends StatefulWidget {
  const Portal({Key key, @required this.child})
      : assert(child != null),
        super(key: key);

  final Widget child;

  @override
  _PortalState createState() => _PortalState();
}

class _PortalState extends State<Portal> {
  final _overlayLink = _OverlayLink();

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

class _OverlayLink {
  _RenderPortalTheater theater;
  BoxConstraints get constraints => theater.constraints;

  final Set<RenderBox> overlays = {};
}

class _PortalLinkScope extends InheritedWidget {
  const _PortalLinkScope({
    Key key,
    @required _OverlayLink overlayLink,
    @required Widget child,
  })  : _overlayLink = overlayLink,
        super(key: key, child: child);

  final _OverlayLink _overlayLink;

  @override
  bool updateShouldNotify(_PortalLinkScope oldWidget) {
    return oldWidget._overlayLink != _overlayLink;
  }
}

class _PortalTheater extends SingleChildRenderObjectWidget {
  const _PortalTheater({
    Key key,
    @required _OverlayLink overlayLink,
    @required Widget child,
  })  : _overlayLink = overlayLink,
        super(key: key, child: child);

  final _OverlayLink _overlayLink;

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
  _RenderPortalTheater(_OverlayLink _overlayLink) {
    overlayLink = _overlayLink;
  }

  _OverlayLink _overlayLink;
  _OverlayLink get overlayLink => _overlayLink;
  set overlayLink(_OverlayLink value) {
    assert(value != null, 'overlayLink cannot be null');
    if (_overlayLink != value) {
      assert(
        value.theater == null,
        'overlayLink already assigned to another portal',
      );
      _overlayLink?.theater = null;
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
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    for (final overlay in overlayLink.overlays) {
      if (overlay?.hitTest(result, position: position) ?? false) {
        return true;
      }
    }

    return super.hitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<_OverlayLink>('overlayLink', overlayLink),
    );
  }
}

class PortalEntry extends StatefulWidget {
  const PortalEntry({
    Key key,
    this.visible = true,
    this.childAnchor,
    this.portalAnchor,
    this.portal,
    this.closeDuration,
    @required this.child,
  })  : assert(child != null),
        assert(visible == false || portal != null),
        assert((childAnchor == null) == (portalAnchor == null)),
        super(key: key);

  // ignore: diagnostic_describe_all_properties, conflicts with closeDuration
  final bool visible;
  final Alignment portalAnchor;
  final Alignment childAnchor;
  final Widget portal;
  final Widget child;
  final Duration closeDuration;

  @override
  _PortalEntryState createState() => _PortalEntryState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Alignment>('portalAnchor', portalAnchor))
      ..add(DiagnosticsProperty<Alignment>('childAnchor', childAnchor))
      ..add(DiagnosticsProperty<Duration>('closeDuration', closeDuration))
      ..add(DiagnosticsProperty<Widget>('portal', portal))
      ..add(DiagnosticsProperty<Widget>('child', child));
  }
}

class _PortalEntryState extends State<PortalEntry> {
  final _link = LayerLink();
  bool _visible;
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _visible = widget.visible;
  }

  @override
  void didUpdateWidget(PortalEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.visible) {
      if (!oldWidget.visible && _visible) {
        // rebuild when the portal is in progress of being hidden
      } else if (oldWidget.visible && widget.closeDuration != null) {
        _timer?.cancel();
        _timer = Timer(widget.closeDuration, () {
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

    if (widget.portalAnchor == null) {
      return _PortalEntryTheater(
        portal: _visible ? widget.portal : null,
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
                return _PortalEntryTheater(
                  overlayLink: scope._overlayLink,
                  loosen: true,
                  portal: MyCompositedTransformFollower(
                    link: _link,
                    childAnchor: widget.childAnchor,
                    portalAnchor: widget.portalAnchor,
                    targetSize: constraints.biggest,
                    child: widget.portal,
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

class _PortalEntryTheater extends SingleChildRenderObjectWidget {
  const _PortalEntryTheater({
    Key key,
    @required this.portal,
    @required this.overlayLink,
    this.loosen = false,
    @required Widget child,
  })  : assert(child != null, 'child cannot be null'),
        assert(overlayLink != null, 'overlayLink cannot be null'),
        super(key: key, child: child);

  final Widget portal;
  final bool loosen;
  final _OverlayLink overlayLink;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPortalEntry(overlayLink, loosen: loosen);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPortalEntry renderObject,
  ) {
    renderObject
      ..overlayLink = overlayLink
      ..loosen = loosen;
  }

  @override
  SingleChildRenderObjectElement createElement() => _PortalEntryElement(this);
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('loosen', loosen));
    properties.add(
      DiagnosticsProperty<_OverlayLink>('overlayLink', overlayLink),
    );
  }
}

class _RenderPortalEntry extends RenderProxyBox {
  _RenderPortalEntry(this._overlayLink, {@required bool loosen}) {
    this.loosen = loosen;
  }

  bool _needsAddEntryInTheater = false;

  _OverlayLink _overlayLink;
  _OverlayLink get overlayLink => _overlayLink;
  set overlayLink(_OverlayLink value) {
    assert(value != null);
    assert(value.theater != null);
    if (_overlayLink != value) {
      _overlayLink = value;
      markNeedsLayout();
    }
  }

  bool _loosen;
  bool get loosen => _loosen;
  set loosen(bool value) {
    if (value != _loosen) {
      _loosen = value;
      markNeedsLayout();
    }
  }

  RenderBox _branch;
  RenderBox get branch => _branch;
  set branch(RenderBox value) {
    if (_branch != null) {
      _overlayLink.overlays.remove(branch);
      _overlayLink.theater.markNeedsPaint();
      dropChild(_branch);
    }
    _branch = value;
    if (_branch != null) {
      markNeedsAddEntryInTheater();
      adoptChild(_branch);
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
      _branch.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    if (_branch != null) {
      _overlayLink.overlays.remove(branch);
      _overlayLink.theater.markNeedsPaint();
      _branch.detach();
    }
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    overlayLink.theater.markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (branch != null) {
      if (loosen) {
        branch.layout(overlayLink.constraints.loosen());
      } else {
        branch.layout(BoxConstraints.tight(overlayLink.constraints.biggest));
      }
      if (_needsAddEntryInTheater) {
        _needsAddEntryInTheater = false;
        _overlayLink.overlays.add(branch);
        _overlayLink.theater.markNeedsPaint();
      }
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == branch) {
      // ignore all transformations applied between Portal and PortalEntry
      transform.setFrom(overlayLink.theater.getTransformTo(null));
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    if (branch != null) {
      redepthChild(branch);
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    if (branch != null) {
      visitor(branch);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<_OverlayLink>('overlayLink', overlayLink));
    properties.add(DiagnosticsProperty<bool>('loosen', loosen));
    properties.add(DiagnosticsProperty<RenderBox>('branch', branch));
  }
}

class _PortalEntryElement extends SingleChildRenderObjectElement {
  _PortalEntryElement(_PortalEntryTheater widget) : super(widget);

  @override
  _PortalEntryTheater get widget => super.widget as _PortalEntryTheater;

  @override
  _RenderPortalEntry get renderObject =>
      super.renderObject as _RenderPortalEntry;

  Element _branch;

  final _branchSlot = 42;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _branch = updateChild(_branch, widget.portal, _branchSlot);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _branch = updateChild(_branch, widget.portal, _branchSlot);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // branch first so that it is unmounted before the main tree
    if (_branch != null) {
      visitor(_branch);
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

/// The error that will be thrown if [_PortalEntryTheater] fails to find the specified [Portal].
class PortalNotFoundError<T extends Portal> extends Error {
  PortalNotFoundError._(this._portalEntry);

  final PortalEntry _portalEntry;

  @override
  String toString() {
    return '''
Error: Could not find a $T above this $_portalEntry.
''';
  }
}
