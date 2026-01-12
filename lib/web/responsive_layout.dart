import 'package:capstone_app/web/dimensions.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget Function() desktopBody;
  final Widget Function() tabletBody;
  final Widget Function() mobileBody;

  const ResponsiveLayout({required this. desktopBody, required this.tabletBody, required this.mobileBody, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileWidth) {
          return mobileBody();
        } else if (constraints.maxWidth < tabletWidth) {
          return tabletBody();
        }
        else {
          return desktopBody();
        }
      },
    );
  }
}