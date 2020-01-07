import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MyFollower extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be null. If it was also provided to a
  /// [CompositedTransformTarget], that widget must come earlier in the paint
  /// order.
  ///
  /// The [showWhenUnlinked] and [offset] properties must also not be null.
  const MyFollower({
    Key key,
    @required this.link,
    @required this.targetSize,
    this.showWhenUnlinked = true,
    Widget child,
  })  : assert(link != null),
        assert(showWhenUnlinked != null),
        super(key: key, child: child);

  /// The link object that connects this [CompositedTransformFollower] with a
  /// [CompositedTransformTarget].
  ///
  /// This property must not be null.
  final LayerLink link;

  final Size targetSize;

  /// Whether to show the widget's contents when there is no corresponding
  /// [CompositedTransformTarget] with the same [link].
  ///
  /// When the widget is linked, the child is positioned such that it has the
  /// same global position as the linked [CompositedTransformTarget].
  ///
  /// When the widget is not linked, then: if [showWhenUnlinked] is true, the
  /// child is visible and not repositioned; if it is false, then child is
  /// hidden.
  final bool showWhenUnlinked;

  @override
  MyRenderFollowerLayer createRenderObject(BuildContext context) {
    return MyRenderFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      targetSize: targetSize,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MyRenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..targetSize = targetSize
      ..showWhenUnlinked = showWhenUnlinked;
  }
}

class MyRenderFollowerLayer extends RenderFollowerLayer {
  /// Creates a render object that uses a [FollowerLayer].
  ///
  /// The [link] and [offset] arguments must not be null.
  MyRenderFollowerLayer({
    @required LayerLink link,
    bool showWhenUnlinked = true,
    RenderBox child,
    Size targetSize,
  })  : assert(targetSize != null),
        super(link: link, showWhenUnlinked: showWhenUnlinked) {
    this.targetSize = targetSize;
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
  void paint(PaintingContext context, Offset offset) {
    assert(showWhenUnlinked != null);
    if (layer == null) {
      print('initLayers $link ');
      layer = FollowerLayer(
        link: link,
        showWhenUnlinked: showWhenUnlinked,
        linkedOffset: Offset(-0, -size.height),
        unlinkedOffset: offset,
      );
    } else {
      layer
        ..link = link
        ..showWhenUnlinked = showWhenUnlinked
        ..linkedOffset = Offset(0, size.height)
        ..unlinkedOffset = offset;
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('targetSize', targetSize));
  }
}
