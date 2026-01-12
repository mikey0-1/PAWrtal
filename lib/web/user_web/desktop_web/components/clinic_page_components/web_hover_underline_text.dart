import 'package:flutter/material.dart';

class WebHoverUnderlineText extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;

  const WebHoverUnderlineText({
    super.key,
    required this.text,
      this.onTap,
  });

  @override
  State<WebHoverUnderlineText> createState() => _WebHoverUnderlineTextState();
}

class _WebHoverUnderlineTextState extends State<WebHoverUnderlineText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationThickness: 2,
            decorationColor: Colors.black
          ),
        ),
      ),
    );
  }
}