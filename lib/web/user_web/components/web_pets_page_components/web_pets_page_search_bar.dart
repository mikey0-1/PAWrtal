import 'package:flutter/material.dart';

class WebPetsPageSearchBar extends StatefulWidget {
  const WebPetsPageSearchBar({super.key});

  @override
  State<WebPetsPageSearchBar> createState() => _WebPetsPageSearchBarState();
}

class _WebPetsPageSearchBarState extends State<WebPetsPageSearchBar> {

  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _showClear = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: _controller,
        onTap: () {
          setState(() {
            _showClear = _controller.text.isNotEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: const TextStyle(
            fontSize: 14
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 1.5
            )
          ),
          suffixIcon: _showClear 
          ? IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _controller.clear();
              setState(() {
                _showClear = false;
              });
            },
          )
          : const Icon(Icons.search_rounded)
        )
      ),
    );
  }
}
