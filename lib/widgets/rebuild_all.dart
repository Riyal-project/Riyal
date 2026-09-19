import 'package:flutter/widgets.dart';

/// Marks every element in the app dirty — including const widgets and
/// routes already on the back stack — so all of them rebuild on the next
/// frame. Used when the language changes: [MaterialApp] alone only rebuilds
/// what depends on its locale, leaving other screens showing old text.
void rebuildAllElements() {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
}
