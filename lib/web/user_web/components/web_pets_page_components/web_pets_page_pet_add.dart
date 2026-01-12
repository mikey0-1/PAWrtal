// import 'package:flutter/material.dart';

// class WebPetsPagePetAdd extends StatefulWidget {
//   final void Function(String name, String type) onAddPet;

//   const WebPetsPagePetAdd({super.key, required this.onAddPet});

//   @override
//   State<WebPetsPagePetAdd> createState() => _WebPetsPagePetAddState();
// }

// class _WebPetsPagePetAddState extends State<WebPetsPagePetAdd> {

//   final TextEditingController _controller = TextEditingController();
//   bool _showClear = false;
//   String? selectedPetType;

//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(() {
//       setState(() {
//         _showClear = _controller.text.isNotEmpty;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           children: [
//             const Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "Add your pet"
//                 )
//               ],
//             ),
//             //pet name
//             Column(
//               children: [
//                 const Text("Pet name"),
//                 SizedBox(
//                   height: 50,
//                   child: TextField(
//                     controller: _controller,
//                     onTap: () {
//                       setState(() {
//                         _showClear = _controller.text.isNotEmpty;
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Enter pet name',
//                       hintStyle: const TextStyle(
//                         fontSize: 14
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: const BorderSide(
//                           color: Colors.black,
//                           width: 1.5
//                         )
//                       ),
//                       suffixIcon: _showClear 
//                       ? IconButton(
//                         icon: const Icon(Icons.close_rounded),
//                         onPressed: () {
//                           _controller.clear();
//                           setState(() {
//                             _showClear = false;
//                           });
//                         },
//                       )
//                       : const Icon(Icons.pets_rounded)
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Column(
//               children: [
//                 const Text("Pet Type"),
//                 DropdownButton<String>(
//                   value: selectedPetType,
//                   hint: const SizedBox.shrink(),
//                   items: const [
//                     DropdownMenuItem(value: "Dog", child: Text("Dog")),
//                     DropdownMenuItem(value: "Cat", child: Text("Cat"))
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedPetType = value;
//                     });
//                   },
//                 )
//               ],
//             ),
//             Row(
//               children: [
//                 TextButton(
//                   child: const Text(
//                     "Add to pets"
//                   ),
//                   onPressed: () {
//                     if (_controller.text.trim().isEmpty || selectedPetType == null ){
//                       return;
//                     }
//                     widget.onAddPet(_controller.text.trim(), selectedPetType!);
//                   },
//                 )
//               ],
//             )
//           ],
//         ),
//       ],
//     );
//   }
// }