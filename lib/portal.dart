import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// extends InheritedWidget instead of StatfulWidget so that PortalProvider
// can be subclassed to create "scopes".
class PortalProvider extends InheritedWidget {
  PortalProvider({
    Key key,
    Widget child,
  }) : super(
          key: key,
          child: _PortalTheater(child: child),
        );

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}

class _PortalTheater extends RenderObjectWidget {
  _PortalTheater({this.child});

  final Widget child;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPortalTheater();
  }

  @override
  _PortalTheaterElement createElement() {
    return _PortalTheaterElement(this);
  }
}

/// An [Element] that uses a [SingleChildRenderObjectWidget] as its configuration.
///
/// The child is optional.
///
/// This element subclass can be used for RenderObjectWidgets whose
/// RenderObjects use the [RenderObjectWithChildMixin] mixin. Such widgets are
/// expected to inherit from [SingleChildRenderObjectWidget].
class _PortalTheaterElement extends RenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  _PortalTheaterElement(_PortalTheater widget) : super(widget);

  @override
  _PortalTheater get widget => super.widget as _PortalTheater;

  @override
  _RenderPortalTheater get renderObject =>
      super.renderObject as _RenderPortalTheater;

  Element _child;
  _PortalState _secondSlot;
  Element _secondChild;

  void _unmountPortal(_PortalState state) {
    assert(_secondSlot == state);
    _secondSlot = null;
    renderObject.markNeedsLayout();
    // TODO: unmount the Element
    _secondChild = updateChild(_secondChild, null, state);
  }

  void _updatePortal(_PortalState state) {
    _secondSlot = state;
    renderObject.markNeedsLayout();
    print('updatePortal');

    // if (state.widget.portalBuilder != null) {
    // renderObject.secondChildBuilder =
    //     (Size providerSize, Size wrappedWidgetSize, Offset offset) {
    //   owner.buildScope(this, () {
    //     // TODO: full error handling like in LayoutBuilder
    //     final built = state.widget.portalBuilder(
    //       state.context,
    //       providerSize,
    //       wrappedWidgetSize,
    //       offset,
    //     );

    //     _secondChild = updateChild(_secondChild, built, state);
    //   });
    // };
    // } else {
    print('fallback updateChild ${state.widget.portal}');
    _secondChild = updateChild(_secondChild, state.widget.portal, state);
    // _secondChild = updateChild(_secondChild, state.widget.portal, state);
    // }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child);
    if (_secondChild != null) {
      visitor(_secondChild);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    if (_child == child) {
      _child = null;
    } else if (_secondChild == child) {
      _secondChild = null;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void update(_PortalTheater newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void insertChildRenderObject(RenderBox child, _PortalState slot) {
    final renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    if (slot == null) {
      renderObject.child = child;
    } else {
      renderObject.secondChild = child;
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, _PortalState slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    final renderObject = this.renderObject;
    assert(renderObject.child == child || renderObject.secondChild == child);
    if (renderObject.child == child) {
      renderObject.child = null;
    } else if (renderObject.secondChild == child) {
      renderObject..secondChild = null;
      // ..secondChildBuilder = null
    }
    assert(renderObject == this.renderObject);
  }
}

RenderBox _test;

class _RenderPortalTheater extends RenderBox {
  _RenderPortalTheater() {
    _test = this;
  }

  /// Checks whether the given render object has the correct [runtimeType] to be
  /// a child of this render object.
  ///
  /// Does nothing if assertions are disabled.
  ///
  /// Always returns true.
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! RenderBox) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'A $runtimeType expected a child of type $RenderBox but received a '
              'child of type ${child.runtimeType}.'),
          ErrorDescription(
            'RenderObjects expect specific types of children because they '
            'coordinate with their children during layout and paint. For '
            'example, a RenderSliver cannot be the child of a RenderBox because '
            'a RenderSliver does not understand the RenderBox layout protocol.',
          ),
          ErrorSpacer(),
          DiagnosticsProperty<dynamic>(
            'The $runtimeType that expected a $RenderBox child was created by',
            debugCreator,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
          ErrorSpacer(),
          DiagnosticsProperty<dynamic>(
            'The ${child.runtimeType} that did not match the expected child type '
            'was created by',
            child.debugCreator,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    return true;
  }

  RenderBox _child;

  /// The render object's unique child
  RenderBox get child => _child;
  set child(RenderBox value) {
    if (_child != null) dropChild(_child);
    _child = value;
    if (_child != null) adoptChild(_child);
  }

  RenderBox _secondChild;
  // void Function(
  //   Size providerSize,
  //   Size wrappedWidgetSize,
  //   Offset offset,
  // ) secondChildBuilder;

  /// The render object's unique child
  RenderBox get secondChild => _secondChild;
  set secondChild(RenderBox value) {
    if (_secondChild != null) dropChild(_secondChild);
    _secondChild = value;
    if (_secondChild != null) adoptChild(_secondChild);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null) _child.attach(owner);
    if (_secondChild != null) _secondChild.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_child != null) _child.detach();
    if (_secondChild != null) _secondChild.detach();
  }

  @override
  void redepthChildren() {
    if (_child != null) redepthChild(_child);
    if (_secondChild != null) redepthChild(_secondChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null) visitor(_child);
    if (_secondChild != null) visitor(_secondChild);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (child != null) child.toDiagnosticsNode(name: 'child'),
      if (secondChild != null)
        secondChild.toDiagnosticsNode(name: 'secondChild'),
    ];
  }

  @override
  void setupParentData(RenderObject child) {
    // We don't actually use the offset argument in BoxParentData, so let's
    // avoid allocating it at all.
    if (child.parentData is! ParentData) child.parentData = ParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null) return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    assert(child != null);
    invokeLayoutCallback((BoxConstraints callback) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
      print('didLayout first child');
      print('hasSecond child: $secondChild');

      // if (secondChildBuilder != null) {
      //   final originTranslation =
      //       _reporter.getTransformTo(this).getTranslation();
      //   _wrappedOffset = Offset(originTranslation.x, originTranslation.y);
      //   print('here $_wrappedOffset');
      //   secondChildBuilder?.call(size, _wrappedSize, _wrappedOffset);
      // }
      if (secondChild != null) {
        secondChild.layout(BoxConstraints.tight(size));
      }
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child, offset);
    if (secondChild != null) context.paintChild(secondChild, offset);
  }
}

class Portal extends StatefulWidget {
  Portal({
    Key key,
    @required this.child,
    bool visible = false,
    @required Widget portal,
  })  : assert(child != null),
        portal = visible ? portal : null,
        super(key: key);

  final Widget portal;
  final Widget child;

  @override
  _PortalState createState() => _PortalState();
}

class _PortalState extends State<Portal> {
  bool dirty;
  _PortalTheaterElement element;

  @override
  void initState() {
    super.initState();
    dirty = widget.portal != null;
    updatePortal();
  }

  @override
  void didUpdateWidget(Portal oldWidget) {
    super.didUpdateWidget(oldWidget);
    dirty = widget.portal != oldWidget.portal;
  }

  @override
  Widget build(BuildContext context) {
    if (dirty) {
      updatePortal();
    }
    return _WrappedSizeReporter(child: widget.child);
  }

  void updatePortal() {
    context.visitAncestorElements((e) {
      if (e is _PortalTheaterElement) {
        element = e;
        e._updatePortal(this);
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    element?._unmountPortal(this);
    super.dispose();
  }
}

Size _wrappedSize;
Offset _wrappedOffset;
RenderBox _reporter;

class _WrappedSizeReporter extends SingleChildRenderObjectWidget {
  _WrappedSizeReporter({Key key, Widget child}) : super(key: key, child: child);

  @override
  _Reporter createRenderObject(BuildContext context) {
    return _Reporter();
  }
}

class _Reporter extends RenderProxyBox {
  @override
  void performLayout() {
    _reporter = this;
    super.performLayout();
    print('report size: $size');
    _test?.markNeedsLayout();
    _wrappedSize = size;
  }

  @override
  void markNeedsLayout() {
    _test.markNeedsLayout();
    super.markNeedsLayout();
  }
}
