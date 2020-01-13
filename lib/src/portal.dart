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

    renderObject.branchBuilder = () {
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
    if (child == _branch) {
      _branch = null;
    } else {
      super.forgetChild(child);
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    if (slot == _branchSlot) {
      renderObject.branch = child as RenderBox;
    } else {
      super.insertChildRenderObject(child, slot);
    }
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    if (slot != _branchSlot) {
      super.moveChildRenderObject(child, slot);
    }
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    if (child == renderObject.branch) {
      renderObject.branch = null;
    } else {
      super.removeChildRenderObject(child);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void unmount() {
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
      child.layout(constraints, parentUsesSize: true);
      size = child.size;

      if (branchBuilder != null) {
        invokeLayoutCallback((dynamic _) {
          branchBuilder();
        });
      }

      branch?.layout(BoxConstraints.tight(size));
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
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    if (branch?.hitTest(result, position: position) ?? false) {
      return true;
    }

    return child?.hitTest(result, position: position) ?? false;
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
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
  }

  void removeEntry(_RenderPortalLink entryKey) {
    final removedEntry = _entries[entryKey];

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
    _entries.putIfAbsent(entryKey, () {
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
      renderObject?.markNeedsLayout();
      // TODO: relayout only the given entry if possible
      // The difficulty is about only making the entry as needing build
      // while we need to update its element (curently done through `builders`)
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, _RenderPortalLink slot) {
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    var i = 0;
    for (final entry in _entries.values) {
      properties.add(DiagnosticsProperty('entry ${i++}', entry));
    }
  }
}

class _EntryDetails extends DiagnosticableTree with DiagnosticableMixin {
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
            : MyCompositedTransformFollower(
                targetSize: size,
                childAnchor: childAnchor,
                portalAnchor: portalAnchor,
                link: link,
                child: portal,
              ),
        slot,
      );
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('size', size));
    properties.add(DiagnosticsProperty('link', link));
    properties.add(DiagnosticsProperty('element', element));
    properties.add(DiagnosticsProperty('renderObject', renderObject));
    properties.add(DiagnosticsProperty('childAnchor', childAnchor));
    properties.add(DiagnosticsProperty('portalAnchor', portalAnchor));
  }
}

class _PortalTheaterParentData extends ContainerBoxParentData {}

class MyCompositedTransformFollower extends SingleChildRenderObjectWidget {
  const MyCompositedTransformFollower({
    Key key,
    @required this.link,
    this.targetSize,
    this.childAnchor,
    this.portalAnchor,
    Widget child,
  }) : super(key: key, child: child);

  final Alignment childAnchor;
  final Alignment portalAnchor;
  final LayerLink link;
  final Size targetSize;

  @override
  MyRenderFollowerLayer createRenderObject(BuildContext context) {
    return MyRenderFollowerLayer(link: link)
      ..targetSize = targetSize
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;
  }

  @override
  void updateRenderObject(
      BuildContext context, MyRenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..targetSize = targetSize
      ..childAnchor = childAnchor
      ..portalAnchor = portalAnchor;
  }
}

class MyRenderFollowerLayer extends RenderProxyBox {
  MyRenderFollowerLayer({
    @required LayerLink link,
    RenderBox child,
  })  : _link = link,
        super(child);

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
    if (_link == value) return;
    if (_link == null || value == null) {
      markNeedsCompositingBitsUpdate();
      markNeedsLayoutForSizedByParentChange();
    }
    _link = value;
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
  bool get alwaysNeedsCompositing => link != null;

  @override
  bool get sizedByParent => link == null;

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
    if (link == null) {
      return super.hitTestChildren(result, position: position);
    }
    return result.addWithPaintTransform(
      transform: getCurrentTransform(),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    if (sizedByParent) {
      child.layout(BoxConstraints.tight(size));
    } else {
      super.performLayout();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (link == null) {
      layer = null;
      super.paint(context, offset);
      return;
    }

    final linkedOffset = childAnchor.withinRect(
          Rect.fromLTWH(0, 0, targetSize.width, targetSize.height),
        ) -
        portalAnchor.withinRect(Rect.fromLTWH(0, 0, size.width, size.height));

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
    if (link != null) transform.multiply(getCurrentTransform());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));

    properties.add(DiagnosticsProperty('childAnchor', childAnchor));
    properties.add(DiagnosticsProperty('portalAnchor', portalAnchor));
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}

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
      size = constraints.biggest;

      final entriesConstraints = BoxConstraints.loose(size);

      // not using for-in because `builders` can be mutated inside the layout callback
      for (var i = 0; i < builders.length; i++) {
        final builder = builders[i];
        invokeLayoutCallback<Constraints>((_) {
          builder();
        });
      }

      for (var child = firstChild; child != null; child = childAfter(child)) {
        child.layout(entriesConstraints);
      }
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

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    // don't capture click if clicking on the theather but not an entry
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if ((child as RenderBox).hitTest(result, position: position)) {
        return true;
      }
    }

    return false;
  }
}

class PortalEntry<T extends Portal> extends StatefulWidget {
  PortalEntry({
    Key key,
    this.visible = true,
    this.childAnchor,
    this.portalAnchor,
    this.portal,
    @required this.child,
  })  : assert(visible == false || portal != null),
        assert((childAnchor == null && portalAnchor == null) ||
            (childAnchor != null && portalAnchor != null)),
        assert(child != null),
        super(key: key);

  final Widget portal;
  final Widget child;
  final Alignment childAnchor;
  final Alignment portalAnchor;
  final bool visible;

  @override
  _PortalEntryState<T> createState() => _PortalEntryState<T>();

  @override
  bool operator ==(Object other) {
    return other is PortalEntry &&
        visible == other.visible &&
        child == other.child &&
        portal == other.portal &&
        childAnchor == other.childAnchor &&
        portalAnchor == other.portalAnchor;
  }

  @override
  int get hashCode {
    return hashValues(portal, child, childAnchor, portalAnchor, visible);
  }

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
      portalEntry: widget,
      link: widget.childAnchor != null && widget.portalAnchor != null
          ? layerLink
          : null,
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
    @required this.link,
    @required this.portalEntry,
    Widget child,
  }) : super(key: key, child: child);

  final LayerLink link;
  final PortalEntry portalEntry;

  @override
  _RenderPortalLink createRenderObject(BuildContext context) {
    return _RenderPortalLink()
      ..entry = portalEntry
      ..link = link
      ..theater = dependOnTheater(context);
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
      ..entry = portalEntry
      ..link = link
      ..theater = dependOnTheater(context);
  }
}

class _RenderPortalLink extends RenderProxyBox {
  LayerLink _link;
  LayerLink get link => _link;
  set link(LayerLink link) {
    if (_link != link) {
      _link = link;
      markNeedsLayout();
    }
  }

  PortalEntry _entry;
  PortalEntry get entry => _entry;
  set entry(PortalEntry value) {
    if (_entry != value) {
      _entry = value;
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

    theater?.updateEntry(
      this,
      size,
      entry.visible ? entry.portal : null,
      link,
      childAnchor: entry.childAnchor,
      portalAnchor: entry.portalAnchor,
    );
  }

  @override
  void detach() {
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
