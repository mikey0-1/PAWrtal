// import 'package:flutter/material.dart';

// class APFirstTab extends StatefulWidget {
//   const APFirstTab({super.key});

//   @override
//   State<APFirstTab> createState() => _APFirstTabState();
// }

// class _APFirstTabState extends State<APFirstTab> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 248, 253, 255),
//       body: ListView(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.grey,
//                     blurRadius: 1.0,
//                     spreadRadius: 1,
//                     offset: Offset(0, 2)
//                   )
//                 ]
//               ),
//               child: const Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Padding(
//                         padding: EdgeInsets.only(right: 10),
//                         child: Icon(Icons.timer_rounded),
//                       ),
//                       Text("9 : 00 - 10 : 00 AM")
//                     ],
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(top: 10),
//                     child: Text(
//                       "Clinic name",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 22,
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(top: 5),
//                     child: Text(
//                       "Type of Service",
//                       style: TextStyle(
//                         fontStyle: FontStyle.italic,
//                         fontSize: 16
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }