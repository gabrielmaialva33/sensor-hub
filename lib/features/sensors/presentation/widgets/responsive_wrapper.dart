import 'package:flutter/material.dart';

/// Widget wrapper responsivo para prevenir overflow
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool wrapInScrollView;
  final bool useFlexible;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.wrapInScrollView = false,
    this.useFlexible = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    // Wrap in Flexible for Row/Column children
    if (useFlexible) {
      content = Flexible(child: content);
    }
    // Wrap in ScrollView for overflow prevention
    if (wrapInScrollView) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
      return content;
    }
  }

  /// Extension methods for responsive widgets
  extension ResponsiveExtensions

  on Widget

  {

  Widget get flexible => Flexible(child: this);

  Widget get expanded => Expanded(child: this);

  Widget get scrollableH =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: this);

  Widget get scrollableV =>
      SingleChildScrollView(scrollDirection: Axis.vertical, child: this);
