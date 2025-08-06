import 'package:flutter/material.dart';

class FilterSliverDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  FilterSliverDelegate({
    required this.child,
    this.height = 56.0,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}

class TransactionFilterSection extends StatelessWidget {
  final List<Widget> filterChips;
  final double horizontalPadding;

  const TransactionFilterSection({
    super.key,
    required this.filterChips,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverPersistentHeader(
      pinned: true,
      delegate: FilterSliverDelegate(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterChips
                  .expand((chip) => [chip, const SizedBox(width: 8)])
                  .take(filterChips.length * 2 - 1)
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}