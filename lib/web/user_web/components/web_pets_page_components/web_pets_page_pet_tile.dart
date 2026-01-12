// import 'package:capstone_app/data/models/pet_model.dart';
// import 'package:flutter/material.dart';

// class WebPetsPagePetTile extends StatefulWidget {
//   final Pet pet;
//   final VoidCallback onTap;
//   final bool isSelected;

//   const WebPetsPagePetTile({
//     super.key,
//     required this.pet,
//     required this.onTap,
//     this.isSelected = false,
//   });

//   @override
//   State<WebPetsPagePetTile> createState() => _WebPetsPagePetTileState();
// }

// class _WebPetsPagePetTileState extends State<WebPetsPagePetTile> {
//   bool _isHovering = false;

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovering = true),
//       onExit: (_) => setState(() => _isHovering = false),
//       child: GestureDetector(
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           decoration: BoxDecoration(
//             color: widget.isSelected 
//                 ? const Color(0xFF3498DB).withOpacity(0.05)
//                 : (_isHovering ? Colors.grey.shade50 : Colors.white),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: widget.isSelected 
//                   ? const Color(0xFF3498DB)
//                   : (_isHovering ? const Color(0xFF3498DB).withOpacity(0.3) : Colors.grey.shade300),
//               width: widget.isSelected ? 2 : 1,
//             ),
//             boxShadow: [
//               if (_isHovering || widget.isSelected)
//                 BoxShadow(
//                   color: widget.isSelected 
//                       ? const Color(0xFF3498DB).withOpacity(0.2)
//                       : Colors.grey.withOpacity(0.1),
//                   spreadRadius: widget.isSelected ? 2 : 1,
//                   blurRadius: widget.isSelected ? 8 : 4,
//                   offset: const Offset(0, 2),
//                 ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Pet Image
//               Expanded(
//                 flex: 3,
//                 child: Container(
//                   width: double.infinity,
//                   decoration: const BoxDecoration(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(16),
//                       topRight: Radius.circular(16),
//                     ),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(16),
//                       topRight: Radius.circular(16),
//                     ),
//                     child: Image.network(
//                       widget.pet.image ?? 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop',
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Container(
//                         color: Colors.grey.shade200,
//                         child: Icon(
//                           Icons.pets,
//                           size: 40,
//                           color: Colors.grey.shade400,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
              
//               // Pet Information
//               Expanded(
//                 flex: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         widget.pet.name,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2C3E50),
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         widget.pet.breed,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[600],
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF3498DB).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           widget.pet.type,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Color(0xFF3498DB),
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }