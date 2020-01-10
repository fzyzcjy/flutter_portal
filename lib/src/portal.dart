import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// extends InheritedWidget instead of StatfulWidget so that PortalProvider
// can be subclassed to create "scopes".
class Portal extends InheritedWidget {
  Portal({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  @override
  PortalElement createElement() => PortalElement(this);
}

class PortalElement extends InheritedElement {
  PortalElement(Portal widget) : super(widget) {
    final portalTheater = PortalTheater();
    _theater = PortalTheaterElement(portalTheater);
    portalTheater._element = _theater;
  }

  @override
  Portal get widget => super.widget as Portal;

  PortalTheaterElement _theater;
  // theater is not a child of this Element, but a child of `Portal` instead
  // We just keep it here to expose it to the main branch.
  PortalTheaterElement get theater => _theater;

  // final _PortalTheaterState theater = _PortalTheaterState();

  @override
  Widget build() {
    return _Portal(
      child: super.build(),
      theater: theater.widget,
      // theater: PortalTheater(theater),
    );
  }
}

class _Portal extends SingleChildRenderObjectWidget {
  _Portal({Widget child, this.theater}) : super(child: child);

  final Widget theater;

  @override
  _RenderPortal createRenderObject(BuildContext context) {
    return _RenderPortal();
  }

  @override
  _PortalElement createElement() => _PortalElement(this);
}

class _PortalElement extends SingleChildRenderObjectElement {
  _PortalElement(_Portal widget) : super(widget);

  @override
  _Portal get widget => super.widget as _Portal;

  @override
  _RenderPortal get renderObject => super.renderObject as _RenderPortal;

  Element _branch;

  final _branchSlot = 42;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    print('PORTAL mount');
    renderObject.branchBuilder = () {
      print('branchBuilder');
      owner.buildScope(this, () {
        _branch = updateChild(_branch, widget.theater, _branchSlot);
      });
    };
  }

  @override
  void visitChildren(visitor) {
    // branch first so that it is unmounted before the main tree
    if (_branch != null) {
      visitor(_branch);
    }
    super.visitChildren(visitor);
  }

  @override
  void forgetChild(Element child) {
    print('PORTAL forgetChild ${child == _branch}  $child');
    if (child == _branch) {
      _branch = null;
    } else {
      super.forgetChild(child);
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    print('PORTAL insertRenderObject $slot $child');
    if (slot == _branchSlot) {
      renderObject.branch = child as RenderBox;
    } else {
      super.insertChildRenderObject(child, slot);
    }
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    print('PORTAL moveChildRenderObject $slot $child');
    if (slot != _branchSlot) {
      super.moveChildRenderObject(child, slot);
    }
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    print('PORTAL removeChildRenderObject $child');
    if (child == renderObject.branch) {
      renderObject.branch = null;
    } else {
      super.removeChildRenderObject(child);
    }
  }

  @override
  void deactivate() {
    print('PORTAL deactivate');
    super.deactivate();
  }

  @override
  void unmount() {
    print('PORTAL unmount');
    super.unmount();
  }
}

class _RenderPortal extends RenderProxyBox {
  bool isPerformingLayout = false;

  RenderBox _branch;
  RenderBox get branch => _branch;
  set branch(RenderBox value) {
    if (_branch != null) dropChild(_branch);
    _branch = value;
    if (_branch != null) adoptChild(_branch);
  }

  void Function() branchBuilder;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (branch != null) branch.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (branch != null) branch.detach();
  }

  @override
  void performLayout() {
    isPerformingLayout = true;
    try {
      print('PORTAL layout first branchBuilder: $branchBuilder');
      child.layout(constraints, parentUsesSize: true);
      size = child.size;

      if (branchBuilder != null) {
        invokeLayoutCallback((dynamic _) {
          branchBuilder();
        });
      }

      print('PORTAL layout second $branch');
      branch?.layout(BoxConstraints.tight(size));
      print('PORTAL layout done');
    } finally {
      isPerformingLayout = false;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (branch != null) {
      context.paintChild(branch, offset);
    }
  }

  @override
  void visitChildren(visitor) {
    super.visitChildren(visitor);
    if (branch != null) {
      visitor(branch);
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    if (branch != null) {
      branch.redepthChildren();
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [
      ...super.debugDescribeChildren(),
      if (branch != null) branch.toDiagnosticsNode(name: 'branch')
    ];
  }
}

// ignore: must_be_immutable
class PortalTheater extends RenderObjectWidget {
  PortalTheaterElement _element;
  @override
  PortalTheaterElement createElement() => _element;

  @override
  RenderPortalTheater createRenderObject(BuildContext context) {
    return RenderPortalTheater();
  }
}

class PortalTheaterElement extends RenderObjectElement {
  PortalTheaterElement(PortalTheater widget) : super(widget);

  final Map<_RenderPortalLink, _EntryDetails> _entries = {};

  @override
  PortalTheater get widget => super.widget as PortalTheater;

  @override
  RenderPortalTheater get renderObject =>
      super.renderObject as RenderPortalTheater;

  @override
  void forgetChild(Element child) {
    final key = _entries.keys.firstWhere((key) {
      return _entries[key].element == child;
    });
    assert(key != null);
    _entries.remove(key);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    for (final entry in _entries.values) {
      renderObject.addBuilder(entry.builder);
    }
  }

  @override
  void deactivate() {
    print('THEATHER deactivate ${renderObject.builders} ');
    super.deactivate();
  }

  @override
  void unmount() {
    print('THEATHER unmount');
    super.unmount();
  }

  void removeEntry(_RenderPortalLink entryKey) {
    final removedEntry = _entries[entryKey];
    print('did remove $removedEntry');
    if (removedEntry == null) return;

    removedEntry.portal = null; // removeChildRenderObject will do its job
    renderObject.markNeedsLayout();
  }

  void updateEntry(
    _RenderPortalLink entryKey,
    Size entrySize,
    Widget portal,
    LayerLink link, {
    Alignment childAnchor,
    Alignment portalAnchor,
  }) {
    final entryDetails = _entries.putIfAbsent(entryKey, () {
      final newEntryDetails = _EntryDetails(this, entryKey);
      renderObject?.addBuilder(newEntryDetails.builder);
      return newEntryDetails;
    })
      ..size = entrySize
      ..portal = portal
      ..link = link
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;

    if (renderObject?.canMarkNeedsLayout ?? false) {
      // TODO: relayout only the given entry if possible
      entryDetails?.renderObject?.markNeedsLayout();
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, _RenderPortalLink slot) {
    print('THEATER insertChildRenderObject $slot $child ');
    _entries[slot].renderObject = child;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child);
  }

  @override
  void moveChildRenderObject(RenderObject child, _RenderPortalLink slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    print('THEATER removeChildRenderObject $child ');
    assert(child.parent == renderObject);
    final key = _entries.keys.firstWhere((key) {
      return _entries[key].renderObject == child;
    });
    assert(key != null);
    final removedEntry = _entries.remove(key);
    renderObject
      ..removeBuilder(removedEntry.builder)
      ..remove(child);
  }

  @override
  void visitChildren(visitor) {
    for (final entry in _entries.values) {
      if (entry.element != null) visitor(entry.element);
    }
  }
}

class _EntryDetails {
  _EntryDetails(this._owner, this.slot);
  final PortalTheaterElement _owner;
  final _RenderPortalLink slot;

  Size size;
  LayerLink link;
  Widget portal;
  Element element;
  RenderObject renderObject;
  Alignment childAnchor;
  Alignment portalAnchor;

  void builder() {
    _owner.owner.buildScope(_owner, () {
      // ignore: invalid_use_of_protected_member
      element = _owner.updateChild(
        element,
        portal == null
            ? null
            : Center(
                child: MyCompositedTransformFollower(
                  targetSize: size,
                  showWhenUnlinked: true,
                  childAnchor: childAnchor,
                  portalAnchor: portalAnchor,
                  link: link,
                  child: portal,
                ),
              ),
        slot,
      );
    });
  }
}

class MyCompositedTransformFollower extends SingleChildRenderObjectWidget {
  const MyCompositedTransformFollower({
    Key key,
    @required this.link,
    this.showWhenUnlinked = true,
    this.targetSize,
    this.childAnchor,
    this.portalAnchor,
    Widget child,
  })  : assert(link != null),
        assert(showWhenUnlinked != null),
        super(key: key, child: child);

  final Alignment childAnchor;
  final Alignment portalAnchor;
  final LayerLink link;
  final bool showWhenUnlinked;
  final Size targetSize;

  @override
  MyRenderFollowerLayer createRenderObject(BuildContext context) {
    return MyRenderFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      targetSize: targetSize,
    )
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;
  }

  @override
  void updateRenderObject(
      BuildContext context, MyRenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..targetSize = targetSize
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;
  }
}

class MyRenderFollowerLayer extends RenderProxyBox {
  MyRenderFollowerLayer({
    @required LayerLink link,
    bool showWhenUnlinked = true,
    Size targetSize,
    RenderBox child,
  })  : assert(link != null),
        assert(showWhenUnlinked != null),
        super(child) {
    this.link = link;
    this.showWhenUnlinked = showWhenUnlinked;
    this.targetSize = targetSize;
  }

  Alignment _childAnchor;
  Alignment get childAnchor => _childAnchor;
  set childAnchor(Alignment childAnchor) {
    if (childAnchor != _childAnchor) {
      _childAnchor = childAnchor;
      markNeedsPaint();
    }
  }

  Alignment _portalAnchor;
  Alignment get portalAnchor => _portalAnchor;
  set portalAnchor(Alignment portalAnchor) {
    if (portalAnchor != _portalAnchor) {
      _portalAnchor = portalAnchor;
      markNeedsPaint();
    }
  }

  LayerLink get link => _link;
  LayerLink _link;
  set link(LayerLink value) {
    assert(value != null);
    if (_link == value) return;
    _link = value;
    markNeedsPaint();
  }

  bool get showWhenUnlinked => _showWhenUnlinked;
  bool _showWhenUnlinked;
  set showWhenUnlinked(bool value) {
    assert(value != null);
    if (_showWhenUnlinked == value) return;
    _showWhenUnlinked = value;
    markNeedsPaint();
  }

  Size get targetSize => _targetSize;
  Size _targetSize;
  set targetSize(Size value) {
    assert(value != null);
    if (_targetSize == value) return;
    _targetSize = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  FollowerLayer get layer => super.layer as FollowerLayer;

  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return result.addWithPaintTransform(
      transform: getCurrentTransform(),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(showWhenUnlinked != null);
    final linkedOffset = childAnchor.withinRect(
          Rect.fromLTWH(
            0,
            0,
            targetSize.width,
            targetSize.height,
          ),
        ) -
        portalAnchor.withinRect(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
        );

    print('$runtimeType $linkedOffset ');

    if (layer == null) {
      layer = FollowerLayer(
        link: link,
        showWhenUnlinked: false,
        linkedOffset: linkedOffset,
      );
    } else {
      layer
        ..link = link
        ..showWhenUnlinked = false
        ..linkedOffset = linkedOffset;
    }

    context.pushLayer(
      layer,
      super.paint,
      Offset.zero,
      childPaintBounds: const Rect.fromLTRB(
        // We don't know where we'll end up, so we have no idea what our cull rect should be.
        double.negativeInfinity,
        double.negativeInfinity,
        double.infinity,
        double.infinity,
      ),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(getCurrentTransform());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties
        .add(DiagnosticsProperty<bool>('showWhenUnlinked', showWhenUnlinked));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
  }
}

class _PortalTheaterParentData extends ContainerBoxParentData {}

class RenderPortalTheater extends RenderBox with ContainerRenderObjectMixin {
  bool get canMarkNeedsLayout =>
      !isPerformingLayout && !(parent as _RenderPortal).isPerformingLayout;

  bool isPerformingLayout = false;
  List<VoidCallback> builders = [];

  void addBuilder(VoidCallback builder) {
    builders.add(builder);
    if (canMarkNeedsLayout) markNeedsLayout();
  }

  void removeBuilder(VoidCallback builder) {
    builders.remove(builder);
    if (canMarkNeedsLayout) markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _PortalTheaterParentData) {
      child.parentData = _PortalTheaterParentData();
    }
  }

  @override
  void performLayout() {
    isPerformingLayout = true;
    try {
      print('THEATER start theater performLayout');
      size = constraints.biggest;

      final entriesConstraints = BoxConstraints.tight(size);

      print('THEATER entries $firstChild');

      print('THEATER childCount before: $childCount ');
      // not using for-in because `builders` can be mutated inside the layout callback
      for (var i = 0; i < builders.length; i++) {
        final builder = builders[i];
        invokeLayoutCallback<Constraints>((_) {
          builder();
        });
      }

      print('THEATER childCount after: $childCount ');

      for (var child = firstChild; child != null; child = childAfter(child)) {
        child.layout(entriesConstraints);
      }
      print('THEATER end theater performLayout');
    } finally {
      isPerformingLayout = false;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      context.paintChild(child, offset);
    }
  }
}

class PortalEntry<T extends Portal> extends StatefulWidget {
  PortalEntry({
    Key key,
    this.visible = false,
    this.childAnchor = Alignment.center,
    this.portalAnchor = Alignment.center,
    @required this.portal,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  final Widget portal;
  final Widget child;
  final Alignment childAnchor;
  final Alignment portalAnchor;
  final bool visible;

  @override
  _PortalEntryState<T> createState() => _PortalEntryState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('visible', value: visible, ifTrue: 'visible'));
    properties.add(DiagnosticsProperty('portalAnchor', portalAnchor));
    properties.add(DiagnosticsProperty('childAnchor', childAnchor));
    properties.add(DiagnosticsProperty('portal', portal));
    properties.add(DiagnosticsProperty('child', child));
  }
}

class _PortalEntryState<T extends Portal> extends State<PortalEntry<T>> {
  final LayerLink layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return _PortalLink<T>(
      visible: widget.visible,
      portal: widget.portal,
      childAnchor: widget.childAnchor,
      portalAnchor: widget.portalAnchor,
      portalEntry: widget,
      link: layerLink,
      child: CompositedTransformTarget(
        link: layerLink,
        child: widget.child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('layerLink', layerLink));
  }
}

class _PortalLink<T extends Portal> extends SingleChildRenderObjectWidget {
  _PortalLink({
    Key key,
    bool visible = false,
    this.childAnchor,
    this.portalAnchor,
    @required Widget portal,
    @required Widget child,
    this.portalEntry,
    this.link,
  })  : assert(child != null),
        portal = visible ? portal : null,
        super(key: key, child: child);

  final Widget portal;
  final LayerLink link;
  final Alignment childAnchor;
  final Alignment portalAnchor;
  final PortalEntry portalEntry;

  @override
  _RenderPortalLink createRenderObject(BuildContext context) {
    return _RenderPortalLink()
      ..portal = portal
      ..theater = dependOnTheater(context)
      ..link = link
      ..portalAnchor = portalAnchor
      ..childAnchor = childAnchor;
  }

  PortalTheaterElement dependOnTheater(BuildContext context) {
    final portalElement =
        context.getElementForInheritedWidgetOfExactType<T>() as PortalElement;
    if (portalElement == null) {
      if (portalEntry.visible) throw PortalNotFoundError<T>._(portalEntry);
      return null;
    }
    context.dependOnInheritedElement(portalElement);
    return portalElement.theater;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPortalLink renderObject,
  ) {
    renderObject
      ..portal = portal
      ..theater = dependOnTheater(context)
      ..link = link
      ..portalAnchor = portalAnchor
      ..childAnchor = childAnchor;
  }

  @override
  void didUnmountRenderObject(_RenderPortalLink renderObject) {
    print('ENTRY unmount');
    // renderObject.theater.removeEntry(renderObject);
    super.didUnmountRenderObject(renderObject);
  }
}

class _RenderPortalLink extends RenderProxyBox {
  LayerLink link;

  Alignment _childAnchor;
  Alignment get childAnchor => _childAnchor;
  set childAnchor(Alignment childAnchor) {
    if (childAnchor != _childAnchor) {
      _childAnchor = childAnchor;
      markNeedsLayout();
    }
  }

  Alignment _portalAnchor;
  Alignment get portalAnchor => _portalAnchor;
  set portalAnchor(Alignment portalAnchor) {
    if (portalAnchor != _portalAnchor) {
      _portalAnchor = portalAnchor;
      markNeedsLayout();
    }
  }

  Widget _portal;
  Widget get portal => _portal;
  set portal(Widget portal) {
    if (portal != _portal) {
      _portal = portal;
      markNeedsLayout();
    }
  }

  PortalTheaterElement _theater;
  PortalTheaterElement get theater => _theater;
  set theater(PortalTheaterElement theater) {
    if (theater != _theater) {
      _theater = theater;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    print('performLayout ENTRY  $portal');
    theater?.updateEntry(
      this,
      size,
      portal,
      link,
      childAnchor: childAnchor,
      portalAnchor: portalAnchor,
    );
  }

  @override
  void detach() {
    print('RO ENTRY detach');
    theater?.removeEntry(this);
    super.detach();
  }
}

/// The error that will be thrown if [PortalEntry] fails to find the specified [Portal].
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
