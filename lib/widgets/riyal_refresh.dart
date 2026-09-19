import 'package:flutter/cupertino.dart';

import 'riyal_loader.dart';

/// A scroll view you can pull down to refresh: the flipping Riyal coin
/// appears while you pull and keeps flipping until [onRefresh] finishes.
/// Bounces (and can always be pulled) on every platform, so it also works
/// when the content is shorter than the screen.
class RiyalRefreshScrollView extends StatelessWidget {
  /// Same shape as a [ListView]: [children] laid out in a padded list.
  const RiyalRefreshScrollView.list({
    super.key,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    required List<Widget> children,
  }) : _children = children,
       _child = null;

  /// Same shape as a [SingleChildScrollView].
  const RiyalRefreshScrollView.single({
    super.key,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
    required Widget child,
  }) : _child = child,
       _children = null;

  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry padding;
  final List<Widget>? _children;
  final Widget? _child;

  static Widget _coin(
    BuildContext context,
    RefreshIndicatorMode mode,
    double pulledExtent,
    double triggerDistance,
    double indicatorExtent,
  ) {
    final t = (pulledExtent / triggerDistance).clamp(0.0, 1.0);
    return Center(
      child: Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: const RiyalLoader(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    slivers: [
      CupertinoSliverRefreshControl(
        onRefresh: onRefresh,
        builder: _coin,
        refreshIndicatorExtent: 56,
      ),
      SliverPadding(
        padding: padding,
        sliver: _children != null
            ? SliverList(delegate: SliverChildListDelegate(_children))
            : SliverToBoxAdapter(child: _child),
      ),
    ],
  );
}
