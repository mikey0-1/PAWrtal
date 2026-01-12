import 'package:flutter/material.dart';

class WebLike extends StatefulWidget {
  const WebLike({super.key});

  @override
  State<WebLike> createState() => _WebLikeState();
}

class _WebLikeState extends State<WebLike> {

bool _isClicked = false; 

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10)
      ),
      onTap: () {
        setState(() {
          _isClicked = !_isClicked;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(
              _isClicked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isClicked ? Colors.red : Colors.black,
              size: 20
            ),
        
            const SizedBox(width: 8),
        
            Text(
              _isClicked ? "Saved": "Save",
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w600,
                fontSize: 14
              ),
            ),
          ],
        ),
      ),
    );
  }
}