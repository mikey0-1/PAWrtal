import 'package:capstone_app/mobile/user/pages/pet_card_creation.dart';
import 'package:flutter/material.dart';

class MyFabPets extends StatefulWidget {
  const MyFabPets ({super.key});

  @override
  State<MyFabPets> createState() => _MyFabPetsState();
}

class _MyFabPetsState extends State<MyFabPets> {

  void _petCardCreationPopUp() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PetCardCreation(),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: "btn2",
      onPressed: _petCardCreationPopUp,
      elevation: 5,
      child: const Icon(
        Icons.add_rounded,
      ),
    );
  }
}