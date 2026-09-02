import 'package:flutter/material.dart';

import '../styles.dart';

enum ResponsiveSize { mobile, tablet, desktop }

abstract final class Responsive {
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1200;
  static const double tabletMaxWidth = 720;
  static const double desktopMaxWidth = 1440;
  static const double detailMaxWidth = 980;

  static ResponsiveSize sizeForWidth(double width) {
    if (width < mobileBreakpoint) return ResponsiveSize.mobile;
    if (width < desktopBreakpoint) return ResponsiveSize.tablet;
    return ResponsiveSize.desktop;
  }

  static ResponsiveSize of(BuildContext context) {
    return sizeForWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isMobile(BuildContext context) {
    return of(context) == ResponsiveSize.mobile;
  }

  static bool isTablet(BuildContext context) {
    return of(context) == ResponsiveSize.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return of(context) == ResponsiveSize.desktop;
  }

  static double maxContentWidthForWidth(double width) {
    return switch (sizeForWidth(width)) {
      ResponsiveSize.mobile => width,
      ResponsiveSize.tablet => tabletMaxWidth,
      ResponsiveSize.desktop => desktopMaxWidth,
    };
  }

  static EdgeInsets pagePaddingForWidth(double width) {
    return switch (sizeForWidth(width)) {
      ResponsiveSize.mobile => const EdgeInsets.symmetric(horizontal: 16),
      ResponsiveSize.tablet => const EdgeInsets.symmetric(horizontal: 20),
      ResponsiveSize.desktop => const EdgeInsets.symmetric(horizontal: 32),
    };
  }

  static double bottomSafePaddingForWidth(double width) {
    return switch (sizeForWidth(width)) {
      ResponsiveSize.mobile => 124,
      ResponsiveSize.tablet => 118,
      ResponsiveSize.desktop => 36,
    };
  }

  static int columns(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
  }) {
    return switch (of(context)) {
      ResponsiveSize.mobile => mobile,
      ResponsiveSize.tablet => tablet,
      ResponsiveSize.desktop => desktop,
    };
  }
}

class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final contentWidth =
            maxWidth ?? Responsive.maxContentWidthForWidth(viewportWidth);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Padding(
              padding: padding ?? Responsive.pagePaddingForWidth(viewportWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.topPadding = 8,
    this.bottomPadding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final double topPadding;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final horizontal =
            padding ?? Responsive.pagePaddingForWidth(screenWidth);
        final contentWidth =
            maxWidth ?? Responsive.maxContentWidthForWidth(screenWidth);
        final effectivePadding = EdgeInsets.fromLTRB(
          horizontal.left,
          topPadding,
          horizontal.right,
          bottomPadding ?? Responsive.bottomSafePaddingForWidth(screenWidth),
        );

        return SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppStyles.pageStart, AppStyles.pageEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Padding(
                    padding: effectivePadding,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
