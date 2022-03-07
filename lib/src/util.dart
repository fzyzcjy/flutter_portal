import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
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
