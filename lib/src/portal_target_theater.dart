import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'anchor.dart';
import 'portal_link.dart';

class PortalTargetTheater extends SingleChildRenderObjectWidget {
  const PortalTargetTheater({
    Key? key,
    required this.portalFollower,
    required this.portalLink,
    required this.anchor,
    required this.targetSize,
    required Widget child,
  }) : super(key: key, child: child);

  final Widget? portalFollower;
  final Anchor anchor;
  final PortalLink portalLink;
  final Size targetSize;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPortalTargetTheater(
      portalLink,
      anchor: anchor,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPortalTargetTheater renderObject,
  ) {
    renderObject
      ..portalLink = portalLink
      ..anchor = anchor
      ..targetSize = targetSize;
  }

  @override
  SingleChildRenderObjectElement createElement() =>
      _PortalTargetTheaterElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Anchor>('anchor', anchor));
    properties.add(DiagnosticsProperty<Size>('targetSize', targetSize));
    properties.add(
      DiagnosticsProperty<PortalLink>('portalLink', portalLink),
    );
  }
}

class _RenderPortalTargetTheater extends RenderProxyBox {
  _RenderPortalTargetTheater(
    this._portalLink, {
    required Anchor anchor,
    required Size targetSize,
  })  : assert(_portalLink.theater != null),
        _anchor = anchor,
        _targetSize = targetSize;

  bool _needsAddEntryInTheater = false;

  PortalLink get portalLink => _portalLink;
  PortalLink _portalLink;

  set portalLink(PortalLink value) {
    assert(value.theater != null);
    if (_portalLink != value) {
      _portalLink = value;
      markNeedsLayout();
    }
  }

  Anchor get anchor => _anchor;
  Anchor _anchor;

  set anchor(Anchor value) {
    if (value != _anchor) {
      _anchor = value;
      markNeedsLayout();
    }
  }

  Size get targetSize => _targetSize;
  Size _targetSize;

  set targetSize(Size value) {
    if (value != _targetSize) {
      _targetSize = value;
      markNeedsLayout();
    }
  }

  RenderBox? get branch => _branch;
  RenderBox? _branch;

  set branch(RenderBox? value) {
    if (_branch != null) {
      _portalLink.overlays.remove(PortalLinkOverlay(branch!, anchor));
      _portalLink.theater!.markNeedsPaint();
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
      _portalLink.overlays.remove(PortalLinkOverlay(branch!, anchor));
      _portalLink.theater!.markNeedsPaint();
      _branch!.detach();
    }
  }

  @override
  void markNeedsPaint() {
    super.markNeedsPaint();
    portalLink.theater!.markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    if (branch != null) {
      final constraints = anchor.getFollowerConstraints(
        portalConstraints: portalLink.constraints!,
        targetSize: targetSize,
      );
      branch!.layout(constraints);
      if (_needsAddEntryInTheater) {
        _needsAddEntryInTheater = false;
        _portalLink.overlays.add(PortalLinkOverlay(branch!, anchor));
        _portalLink.theater!.markNeedsPaint();
      }
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == branch) {
      // ignore all transformations applied between Portal and PortalTarget
      transform.setFrom(portalLink.theater!.getTransformTo(null));
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
      ..add(DiagnosticsProperty<PortalLink>('portalLink', portalLink))
      ..add(DiagnosticsProperty<Anchor>('anchor', anchor))
      ..add(DiagnosticsProperty<Size>('targetSize', targetSize));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (child != null) child!.toDiagnosticsNode(name: 'child'),
      if (branch != null) branch!.toDiagnosticsNode(name: 'branch'),
    ];
  }
}

class _PortalTargetTheaterElement extends SingleChildRenderObjectElement {
  _PortalTargetTheaterElement(PortalTargetTheater widget) : super(widget);

  @override
  PortalTargetTheater get widget => super.widget as PortalTargetTheater;

  @override
  _RenderPortalTargetTheater get renderObject =>
      super.renderObject as _RenderPortalTargetTheater;

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
