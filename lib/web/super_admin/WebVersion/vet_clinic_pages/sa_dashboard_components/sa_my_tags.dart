import 'package:flutter/material.dart';

class SuperAdminTags extends StatefulWidget {
  const SuperAdminTags({super.key});

  @override
  State<SuperAdminTags> createState() => _MyTagsState();
}

class _MyTagsState extends State<SuperAdminTags> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 10, top: 10, right: 5, bottom: 10),
            child: ChoiceChip(
              elevation: 5,
              selectedColor: const Color.fromRGBO(227, 242, 253, 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0)),
              label: const Text(
                "All",
                style: TextStyle(fontSize: 15),
              ),
              selected: _selectedIndex == 0,
              onSelected: (newState) {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
