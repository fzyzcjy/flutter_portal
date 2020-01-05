import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    super.visitChildren(visitor);
    if (_branch != null) {
      visitor(_branch);
    }
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
  void unmount() {
    print('PORTAL unmount');
    super.unmount();
  }
}

class _RenderPortal extends RenderProxyBox {
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

// class PortalTheater extends StatefulWidget {
//   const PortalTheater(this.state, {Key key}) : super(key: key);

//   final _PortalTheaterState state;

//   @override
//   _PortalTheaterState createState() => state;
// }

// class _PortalTheaterState extends State<PortalTheater> {
//   final Map<RenderPortalEntry, Widget> portals = {};

//   void updateEntry(RenderPortalEntry entry, Size entrySize, Widget portal) {
//     portals[entry] = portal;
//     final context = this.context;
//     if (context is Element && !context.dirty) {
//       context.markNeedsBuild();
//     }
//     // if (context != null) {
//     //   setState(() {});
//     // }
//   }

//   @override
//   void deactivate() {
//     print('deactivate theater');
//     super.deactivate();
//   }

//   @override
//   void dispose() {
//     print('dispose theater');
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       textDirection: TextDirection.ltr,
//       children: <Widget>[
//         for (final portal in portals.values) SizedBox.expand(child: portal)
//       ],
//     );
//   }

//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(DiagnosticsProperty('portals', portals));
//   }
// }

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

  Map<RenderPortalEntry, _EntryDetails> _entries = {};

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
    // TODO: implement mount
    super.mount(parent, newSlot);
    for (final entry in _entries.values) {
      renderObject.addBuilder(entry.builder);
    }
  }

  void removeEntry(RenderPortalEntry entryKey) {
    final removedEntry = _entries.remove(entryKey);
    if (removedEntry == null) return;
    renderObject.removeBuilder(removedEntry.builder);
  }

  void updateEntry(RenderPortalEntry entryKey, Size entrySize, Widget portal) {
    // TODO: relayout only the given entry if possible
    final entryDetails =
        _entries.putIfAbsent(entryKey, () => _EntryDetails(this, entryKey))
          ..size = entrySize
          ..portal = portal;

    renderObject?.addBuilder(entryDetails.builder);
  }

  @override
  void insertChildRenderObject(RenderObject child, RenderPortalEntry slot) {
    _entries[slot].renderObject = child;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child);
  }

  @override
  void moveChildRenderObject(RenderObject child, RenderPortalEntry slot) {
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
}

class _EntryDetails {
  _EntryDetails(this._owner, this.slot);
  final PortalTheaterElement _owner;
  final RenderPortalEntry slot;

  Size size;
  Widget portal;
  Element element;
  RenderObject renderObject;

  void builder() {
    _owner.owner.buildScope(_owner, () {
      // ignore: invalid_use_of_protected_member
      element = _owner.updateChild(element, portal, slot);
    });
  }
}

class _PortalTheaterParentData extends ContainerBoxParentData {}

class RenderPortalTheater extends RenderBox with ContainerRenderObjectMixin {
  List<VoidCallback> builders = [];

  void addBuilder(VoidCallback builder) {
    builders.add(builder);
    // markNeedsLayout();
  }

  void removeBuilder(VoidCallback builder) {
    builders.remove(builder);
    // markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _PortalTheaterParentData) {
      child.parentData = _PortalTheaterParentData();
    }
  }

  @override
  void performLayout() {
    print('start theater performResize');
    size = constraints.biggest;

    final entriesConstraints = BoxConstraints.tight(size);

    print('entries $firstChild');

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
    print('end theater performResize');
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      context.paintChild(child, offset);
    }
  }
}

class PortalEntry extends SingleChildRenderObjectWidget {
  PortalEntry({
    Key key,
    bool visible = false,
    @required Widget portal,
    @required Widget child,
  })  : assert(child != null),
        portal = visible ? portal : null,
        super(key: key, child: child);

  final Widget portal;

  @override
  RenderPortalEntry createRenderObject(BuildContext context) {
    return RenderPortalEntry()
      ..portal = portal
      ..theater = dependOnTheater(context);
  }

  PortalTheaterElement dependOnTheater(BuildContext context) {
    final portalElement = context
        .getElementForInheritedWidgetOfExactType<Portal>() as PortalElement;
    context.dependOnInheritedElement(portalElement);
    return portalElement.theater;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderPortalEntry renderObject,
  ) {
    renderObject
      ..portal = portal
      ..theater = dependOnTheater(context);
  }
}

class RenderPortalEntry extends RenderProxyBox {
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
    theater.updateEntry(this, size, portal);
  }

  @override
  void detach() {
    super.detach();
    theater.removeEntry(this);
  }
}
